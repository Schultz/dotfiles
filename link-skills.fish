#!/usr/bin/env fish
# link-skills.fish — symlink skills/<name>/ into ~/.claude/skills and
# ~/.codex/skills so one SKILL.md serves both tools.
#
# Not stow: those directories already hold real per-tool content, so stowing
# the whole target would conflict. This links one entry per skill instead.
# install.fish and `just link-skills` both call it.

set -l here (status dirname)

function __log; set_color cyan; echo "==> $argv"; set_color normal; end
function __warn; set_color yellow; echo "!! $argv"; set_color normal; end

if not test -d $here/skills
    __warn "no skills/ directory — nothing to link"
    exit 0
end

mkdir -p $HOME/.claude/skills $HOME/.codex/skills

set -l count 0
for pkg in $here/skills/*/
    set -l name (basename $pkg)
    ln -sfn $pkg $HOME/.claude/skills/$name
    ln -sfn $pkg $HOME/.codex/skills/$name
    echo "    linked $name"
    set count (math $count + 1)
end

__log "Linked $count skill(s) into ~/.claude/skills and ~/.codex/skills"
