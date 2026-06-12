# Homebrew formula for pre-flight-check.
#
# Canonical source for this formula. Mirrored to the tap repo
# `mirekondro/homebrew-pre-flight-check` on every release.
#
# After tagging a new version:
#   1. Compute sha256:
#        curl -sL https://github.com/mirekondro/The-Pre-Flight-Check/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
#   2. Update `url` and `sha256` below.
#   3. Commit + push to the tap repo (or this repo's Formula/ dir if using the direct-install path).
#
class PreFlightCheck < Formula
  include Language::Python::Virtualenv

  desc "Fail-fast quality gate for AI coding agents (Typecheck → Lint → Test → Audit)"
  homepage "https://github.com/mirekondro/The-Pre-Flight-Check"
  url "https://github.com/mirekondro/The-Pre-Flight-Check/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "8cbeaa86fbd0f44aed5508b56b34e99ed27f41b7e6bc44b51acd05320617e1e6"
  license "MIT"
  head "https://github.com/mirekondro/The-Pre-Flight-Check.git", branch: "main"

  depends_on "python@3.12"

  # Zero runtime Python dependencies on purpose — keeps the install surface tiny
  # and the supply-chain attack surface zero. If that changes, add resource blocks
  # here. See `brew update-python-resources pre-flight-check`.

  def install
    virtualenv_install_with_resources
  end

  test do
    # Version stamp matches the formula version.
    assert_match version.to_s, shell_output("#{bin}/pre-flight-check --version")

    # `list-tools` always succeeds and lists every supported AI tool.
    out = shell_output("#{bin}/pre-flight-check list-tools")
    %w[claude codex gemini cursor copilot windsurf cline kiro roo agents-skills].each do |tool|
      assert_match tool, out
    end

    # `run` against an empty dir produces the documented UNKNOWN RUNTIME block
    # and exits 1. The non-zero exit is expected, so explicitly tolerate it.
    in_an_empty_dir = testpath/"empty"
    in_an_empty_dir.mkpath
    output = shell_output("cd #{in_an_empty_dir} && #{bin}/pre-flight-check run; true")
    assert_match "PRE-FLIGHT SKIPPED: UNKNOWN RUNTIME", output
  end
end
