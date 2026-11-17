cask "ghostty" do
  version "0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/jonaprieto/ghostty/releases/download/fork-#{version}/Ghostty-#{version}.zip"
  name "Ghostty"
  desc "Terminal emulator with tabs in the quick terminal (personal fork)"
  homepage "https://github.com/jonaprieto/ghostty"

  # Same token and bundle identifier as the official ghostty cask, so only one of them can be installed;
  # always use the full name jonaprieto/tap/ghostty.
  depends_on macos: :ventura

  app "Ghostty.app"
  binary "#{appdir}/Ghostty.app/Contents/MacOS/ghostty"

  # The build is ad-hoc signed and not notarized, so clear the quarantine flag.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-cr", "{{appdir}}/Ghostty.app"]
  end

  caveats <<~EOS
    An ad-hoc signature changes with every build, so macOS asks again for Accessibility
    (needed by a global quick terminal keybind) after each update.
  EOS
end
