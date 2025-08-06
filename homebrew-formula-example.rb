# Example Homebrew formula for a tap
# Place this in: homebrew-tap-name/Formula/zsh-ai-assist.rb

class ZshAiAssist < Formula
  desc "AI-powered command generation and error fixing using Claude AI"
  homepage "https://github.com/MKSG-MugunthKumar/zsh-ai-assist"
  url "https://github.com/MKSG-MugunthKumar/zsh-ai-assist/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"

  depends_on "curl"
  depends_on "jq"

  def install
    # Install zsh plugin
    (share/"zsh/site-functions").install "zsh-ai-assist.plugin.zsh"
    
    # Install fish functions
    (share/"fish/vendor_functions.d").install "functions/ask_claude.fish"
    (share/"fish/vendor_conf.d").install "conf.d/zsh_ai_assist.fish"
    
    # Install documentation
    doc.install "README.md"
    doc.install "CLAUDE.md"
  end

  def caveats
    <<~EOS
      To use zsh-ai-assist with zsh, add this to your ~/.zshrc:
        source #{HOMEBREW_PREFIX}/share/zsh/site-functions/zsh-ai-assist.plugin.zsh

      To use with oh-my-zsh, create a custom plugin:
        mkdir -p $ZSH_CUSTOM/plugins/zsh-ai-assist
        ln -sf #{HOMEBREW_PREFIX}/share/zsh/site-functions/zsh-ai-assist.plugin.zsh $ZSH_CUSTOM/plugins/zsh-ai-assist/
        
      Then add 'zsh-ai-assist' to your plugins array in ~/.zshrc

      Don't forget to set your ANTHROPIC_API_KEY:
        export ANTHROPIC_API_KEY="your-api-key-here"
    EOS
  end

  test do
    # Test that the plugin file exists and is readable
    assert_predicate share/"zsh/site-functions/zsh-ai-assist.plugin.zsh", :exist?
    assert_predicate share/"fish/vendor_functions.d/ask_claude.fish", :exist?
  end
end