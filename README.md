## Install

`sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"`

<div class="wrapper">
   <p id="text">sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"</p>
   <button onclick="copyText()">copy</button>
</div>

<script type="text/javascript">
    function copyText() {
      var text = document.getElementById("text");
      text.innerText.select // 修改文本框的内容
       // 选中文本
      document.execCommand("copy"); // 执行浏览器复制命令
      alert("复制成功");
    }
</script>