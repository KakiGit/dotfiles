#!/usr/bin/env python3
"""Render docker-compose.yml from sandbox.yaml and drive the sandbox container."""
import getpass
import os
import shlex
import shutil
import subprocess
import sys

import yaml

SCRIPT_DIR = os.environ["SANDBOX_SCRIPT_DIR"]
SANDBOX_TYPE = os.environ["SANDBOX_TYPE"]
SANDBOX_DIR = os.environ["SANDBOX_DIR"]
TYPE_DIR = os.path.join(SCRIPT_DIR, SANDBOX_TYPE)
BASE_DEFAULT = os.path.join(SCRIPT_DIR, "sandbox.default.yaml")
TYPE_DEFAULT = os.path.join(TYPE_DIR, "sandbox.default.yaml")
CONFIG = os.path.join(SANDBOX_DIR, "sandbox.yaml")
COMPOSE_FILE = os.path.join(SANDBOX_DIR, "docker-compose.yml")
BASE_DOCKERFILE = os.path.join(TYPE_DIR, "Dockerfile")
OVERLAY_DIR = os.path.join(SANDBOX_DIR, "Dockerfile.d")
GENERATED_DOCKERFILE = os.path.join(TYPE_DIR, "Dockerfile.sandbox")


def load(path):
    with open(path) as f:
        return yaml.safe_load(f) or {}


def read_text(path):
    with open(path) as f:
        return f.read()


def deep_merge(dst, src):
    for key, value in (src or {}).items():
        if isinstance(dst.get(key), list) and isinstance(value, list):
            dst[key] += value
        elif isinstance(dst.get(key), dict) and isinstance(value, dict):
            deep_merge(dst[key], value)
        else:
            dst[key] = value
    return dst


def resolve_runtime(node, runtime):
    """Recursively apply `<runtimes: {runtime: {...}}>` overlays for the active runtime."""
    if isinstance(node, list):
        return [resolve_runtime(item, runtime) for item in node]
    if isinstance(node, dict):
        base = {k: resolve_runtime(v, runtime) for k, v in node.items() if k != "runtimes"}
        overlay = node.get("runtimes", {}).get(runtime, {})
        return deep_merge(base, resolve_runtime(overlay, runtime)) if overlay else base
    return node


def compose_cmd(runtime):
    if os.environ.get("SANDBOX_COMPOSE"):
        return shlex.split(os.environ["SANDBOX_COMPOSE"])
    if runtime == "docker":
        return ["docker", "compose"]
    if shutil.which("podman-compose"):
        return ["podman-compose"]
    if shutil.which("podman"):
        return ["podman", "compose"]
    sys.exit(f"sandbox: no compose provider for runtime '{runtime}'")


def expand_mount(mount):
    if isinstance(mount, str):
        mount = {"source": mount}
    source = str(mount["source"]).replace("~", "${HOME}")
    target = str(mount.get("target", mount["source"])).replace("~", "${HOME}")
    return f"{source}:{target}:{mount.get('options', 'z')}"


def seed_config():
    if os.path.exists(CONFIG):
        return
    config = load(BASE_DEFAULT)
    if os.path.exists(TYPE_DEFAULT):
        deep_merge(config, load(TYPE_DEFAULT))
    with open(CONFIG, "w") as f:
        yaml.safe_dump(config, f, default_flow_style=False, sort_keys=False)


def overlay_dockerfiles():
    """User overlays, applied in sorted filename order (use NN- prefixes)."""
    if not os.path.isdir(OVERLAY_DIR):
        return []
    return sorted(
        os.path.join(OVERLAY_DIR, name)
        for name in os.listdir(OVERLAY_DIR)
        if name.endswith(".Dockerfile")
    )


def compose_dockerfile(overlays):
    """Append user overlay Dockerfiles to the base into one generated file."""
    if not overlays:
        return None
    parts = [read_text(BASE_DOCKERFILE)]
    parts += [f"# ---- {os.path.basename(p)} ----\n{read_text(p)}" for p in overlays]
    with open(GENERATED_DOCKERFILE, "w") as f:
        f.write("\n".join(part.rstrip("\n") for part in parts) + "\n")
    return os.path.basename(GENERATED_DOCKERFILE)


def build_service(config, dockerfile=None):
    user = config.get("user", {})
    service = {
        "build": {
            "context": TYPE_DIR,
            "args": {
                "USERNAME": str(user.get("name", getpass.getuser())),
                "USER_UID": str(user.get("uid", os.getuid())),
                "USER_GID": str(user.get("gid", os.getgid())),
            },
        }
    }
    if dockerfile:
        service["build"]["dockerfile"] = dockerfile
    deep_merge(service, config.get("base"))
    feature_sets = config.get("feature_sets", {})
    for name in config.get("features", []):
        deep_merge(service, feature_sets.get(name, {}))
    mounts = [expand_mount(m) for m in config.get("mounts", [])]
    if mounts:
        service["volumes"] = service.get("volumes", []) + mounts
    return config.get("service", "sandbox"), service


def prepare():
    seed_config()
    raw = load(CONFIG)
    runtime = os.environ.get("CONTAINER_RUNTIME") or raw.get("runtime") or "podman"
    dockerfile = compose_dockerfile(overlay_dockerfiles())
    name, service = build_service(resolve_runtime(raw, runtime), dockerfile)
    with open(COMPOSE_FILE, "w") as f:
        yaml.safe_dump({"services": {name: service}}, f, default_flow_style=False, sort_keys=False)
    return runtime, name


def running(runtime):
    result = subprocess.run([*compose_cmd(runtime), "ps", "-q"], capture_output=True, text=True)
    return bool(result.stdout.strip())


def cmd_build(args):
    runtime, _ = prepare()
    subprocess.run([*compose_cmd(runtime), "build", *args], check=True)


def cmd_up(args):
    if not os.path.exists(CONFIG):
        cmd_build([])
    runtime, _ = prepare()
    subprocess.run([*compose_cmd(runtime), "up", "-d", *args], check=True)


def cmd_exec(args):
    runtime, name = prepare()
    if not running(runtime):
        cmd_up([])
        runtime, name = prepare()
    command = args or [load(CONFIG).get("shell", "fish")]
    cmd = [*compose_cmd(runtime), "exec", name, *command]
    os.execvp(cmd[0], cmd)


def usage():
    print("usage: sandbox.sh [exec|up|build] [args...]")
    print("  exec (default)  open a shell in the sandbox, starting it if needed")
    print("  up              start the sandbox in the background")
    print("  build           (re)build the sandbox image")
    print("other arguments are run as a command inside the sandbox")


def main():
    args = sys.argv[1:]
    action = args[0] if args else "exec"
    if action == "build":
        cmd_build(args[1:])
    elif action == "up":
        cmd_up(args[1:])
    elif action == "exec":
        cmd_exec(args[1:])
    elif action in ("-h", "--help", "help"):
        usage()
    else:
        cmd_exec(args)


if __name__ == "__main__":
    os.chdir(SANDBOX_DIR)
    main()
