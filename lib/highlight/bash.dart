// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `bash`.
///
/// Import this library only when you need `bash` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightBash {
  /// The grammar for `bash`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("shebang", compileHighlightPattern("^#!\\s*\\/.*"),
      alias: "important"),
  GrammarToken("comment", compileHighlightPattern("(^|[^\"{\\\\\$])#.*"),
      lookbehind: true),
  GrammarToken(
      "function-name",
      compileHighlightPattern(
          "(\\bfunction\\s+)[\\w-]+(?=(?:\\s*\\(?:\\s*\\))?\\s*\\{)"),
      lookbehind: true,
      alias: "function"),
  GrammarToken("function-name",
      compileHighlightPattern("\\b[\\w-]+(?=\\s*\\(\\s*\\)\\s*\\{)"),
      alias: "function"),
  GrammarToken("for-or-select",
      compileHighlightPattern("(\\b(?:for|select)\\s+)\\w+(?=\\s+in\\s)"),
      lookbehind: true, alias: "variable"),
  GrammarToken("assign-left",
      compileHighlightPattern("(^|[\\s;|&]|[<>]\\()\\w+(?:\\.\\w+)*(?=\\+?=)"),
      lookbehind: true, alias: "variable", inside: () => _g1),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(^|\\s)-{1,2}(?:\\w+:[+-]?)?\\w+(?:\\.\\w+)*(?=[=\\s]|\$)"),
      lookbehind: true,
      alias: "variable"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "((?:^|[^<])<<-?\\s*)(\\w+)\\s[\\s\\S]*?(?:\\r?\\n|\\r)\\2"),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "((?:^|[^<])<<-?\\s*)([\"'])(\\w+)\\2\\s[\\s\\S]*?(?:\\r?\\n|\\r)\\3"),
      lookbehind: true,
      greedy: true,
      inside: () => _g5),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(^|[^\\\\](?:\\\\\\\\)*)\"(?:\\\\[\\s\\S]|\\\$\\([^)]+\\)|\\\$(?!\\()|`[^`]+`|[^\"\\\\`\$])*\""),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("(^|[^\$\\\\])'[^']*'"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string", compileHighlightPattern("\\\$'(?:[^'\\\\]|\\\\[\\s\\S])*'"),
      greedy: true, inside: () => _g6),
  GrammarToken(
      "environment",
      compileHighlightPattern(
          "\\\$?\\b(?:BASH|BASHOPTS|BASH_ALIASES|BASH_ARGC|BASH_ARGV|BASH_CMDS|BASH_COMPLETION_COMPAT_DIR|BASH_LINENO|BASH_REMATCH|BASH_SOURCE|BASH_VERSINFO|BASH_VERSION|COLORTERM|COLUMNS|COMP_WORDBREAKS|DBUS_SESSION_BUS_ADDRESS|DEFAULTS_PATH|DESKTOP_SESSION|DIRSTACK|DISPLAY|EUID|GDMSESSION|GDM_LANG|GNOME_KEYRING_CONTROL|GNOME_KEYRING_PID|GPG_AGENT_INFO|GROUPS|HISTCONTROL|HISTFILE|HISTFILESIZE|HISTSIZE|HOME|HOSTNAME|HOSTTYPE|IFS|INSTANCE|JOB|LANG|LANGUAGE|LC_ADDRESS|LC_ALL|LC_IDENTIFICATION|LC_MEASUREMENT|LC_MONETARY|LC_NAME|LC_NUMERIC|LC_PAPER|LC_TELEPHONE|LC_TIME|LESSCLOSE|LESSOPEN|LINES|LOGNAME|LS_COLORS|MACHTYPE|MAILCHECK|MANDATORY_PATH|NO_AT_BRIDGE|OLDPWD|OPTERR|OPTIND|ORBIT_SOCKETDIR|OSTYPE|PAPERSIZE|PATH|PIPESTATUS|PPID|PS1|PS2|PS3|PS4|PWD|RANDOM|REPLY|SECONDS|SELINUX_INIT|SESSION|SESSIONTYPE|SESSION_MANAGER|SHELL|SHELLOPTS|SHLVL|SSH_AUTH_SOCK|TERM|UID|UPSTART_EVENTS|UPSTART_INSTANCE|UPSTART_JOB|UPSTART_SESSION|USER|WINDOWID|XAUTHORITY|XDG_CONFIG_DIRS|XDG_CURRENT_DESKTOP|XDG_DATA_DIRS|XDG_GREETER_DATA_DIR|XDG_MENU_PREFIX|XDG_RUNTIME_DIR|XDG_SEAT|XDG_SEAT_PATH|XDG_SESSION_DESKTOP|XDG_SESSION_ID|XDG_SESSION_PATH|XDG_SESSION_TYPE|XDG_VTNR|XMODIFIERS)\\b"),
      alias: "constant"),
  GrammarToken(
      "variable", compileHighlightPattern("\\\$?\\(\\([\\s\\S]+?\\)\\)"),
      greedy: true, inside: () => _g3),
  GrammarToken("variable",
      compileHighlightPattern("\\\$\\((?:\\([^)]+\\)|[^()])+\\)|`[^`]+`"),
      greedy: true, inside: () => _g4),
  GrammarToken("variable", compileHighlightPattern("\\\$\\{[^}]+\\}"),
      greedy: true, inside: () => _g8),
  GrammarToken("variable", compileHighlightPattern("\\\$(?:\\w+|[#?*!@\$])")),
  GrammarToken(
      "function",
      compileHighlightPattern(
          "(^|[\\s;|&]|[<>]\\()(?:add|apropos|apt|apt-cache|apt-get|aptitude|aspell|automysqlbackup|awk|basename|bash|bc|bconsole|bg|bzip2|cal|cargo|cat|cfdisk|chgrp|chkconfig|chmod|chown|chroot|cksum|clear|cmp|column|comm|composer|cp|cron|crontab|csplit|curl|cut|date|dc|dd|ddrescue|debootstrap|df|diff|diff3|dig|dir|dircolors|dirname|dirs|dmesg|docker|docker-compose|du|egrep|eject|env|ethtool|expand|expect|expr|fdformat|fdisk|fg|fgrep|file|find|fmt|fold|format|free|fsck|ftp|fuser|gawk|git|gparted|grep|groupadd|groupdel|groupmod|groups|grub-mkconfig|gzip|halt|head|hg|history|host|hostname|htop|iconv|id|ifconfig|ifdown|ifup|import|install|ip|java|jobs|join|kill|killall|less|link|ln|locate|logname|logrotate|look|lpc|lpr|lprint|lprintd|lprintq|lprm|ls|lsof|lynx|make|man|mc|mdadm|mkconfig|mkdir|mke2fs|mkfifo|mkfs|mkisofs|mknod|mkswap|mmv|more|most|mount|mtools|mtr|mutt|mv|nano|nc|netstat|nice|nl|node|nohup|notify-send|npm|nslookup|op|open|parted|passwd|paste|pathchk|ping|pkill|pnpm|podman|podman-compose|popd|pr|printcap|printenv|ps|pushd|pv|quota|quotacheck|quotactl|ram|rar|rcp|reboot|remsync|rename|renice|rev|rm|rmdir|rpm|rsync|scp|screen|sdiff|sed|sendmail|seq|service|sftp|sh|shellcheck|shuf|shutdown|sleep|slocate|sort|split|ssh|stat|strace|su|sudo|sum|suspend|swapon|sync|sysctl|tac|tail|tar|tee|time|timeout|top|touch|tr|traceroute|tsort|tty|umount|uname|unexpand|uniq|units|unrar|unshar|unzip|update-grub|uptime|useradd|userdel|usermod|users|uudecode|uuencode|v|vcpkg|vdir|vi|vim|virsh|vmstat|wait|watch|wc|wget|whereis|which|who|whoami|write|xargs|xdg-open|yarn|yes|zenity|zip|zsh|zypper)(?=\$|[)\\s;|&])"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^|[\\s;|&]|[<>]\\()(?:case|do|done|elif|else|esac|fi|for|function|if|in|select|then|until|while)(?=\$|[)\\s;|&])"),
      lookbehind: true),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "(^|[\\s;|&]|[<>]\\()(?:\\.|:|alias|bind|break|builtin|caller|cd|command|continue|declare|echo|enable|eval|exec|exit|export|getopts|hash|help|let|local|logout|mapfile|printf|pwd|read|readarray|readonly|return|set|shift|shopt|source|test|times|trap|type|typeset|ulimit|umask|unalias|unset)(?=\$|[)\\s;|&])"),
      lookbehind: true,
      alias: "class-name"),
  GrammarToken(
      "boolean",
      compileHighlightPattern(
          "(^|[\\s;|&]|[<>]\\()(?:false|true)(?=\$|[)\\s;|&])"),
      lookbehind: true),
  GrammarToken("file-descriptor", compileHighlightPattern("\\B&\\d\\b"),
      alias: "important"),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "\\d?<>|>\\||\\+=|=[=~]?|!=?|<<[<-]?|[&\\d]?>>|\\d[<>]&?|[<>][&=]?|&[>&]?|\\|[&|]?"),
      inside: () => _g7),
  GrammarToken("punctuation",
      compileHighlightPattern("\\\$?\\(\\(?|\\)\\)?|\\.\\.|[{}[\\];\\\\]")),
  GrammarToken("number",
      compileHighlightPattern("(^|\\s)(?:[1-9]\\d*|0)(?:[.,]\\d+)?\\b"),
      lookbehind: true),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "environment",
      compileHighlightPattern(
          "(^|[\\s;|&]|[<>]\\()\\b(?:BASH|BASHOPTS|BASH_ALIASES|BASH_ARGC|BASH_ARGV|BASH_CMDS|BASH_COMPLETION_COMPAT_DIR|BASH_LINENO|BASH_REMATCH|BASH_SOURCE|BASH_VERSINFO|BASH_VERSION|COLORTERM|COLUMNS|COMP_WORDBREAKS|DBUS_SESSION_BUS_ADDRESS|DEFAULTS_PATH|DESKTOP_SESSION|DIRSTACK|DISPLAY|EUID|GDMSESSION|GDM_LANG|GNOME_KEYRING_CONTROL|GNOME_KEYRING_PID|GPG_AGENT_INFO|GROUPS|HISTCONTROL|HISTFILE|HISTFILESIZE|HISTSIZE|HOME|HOSTNAME|HOSTTYPE|IFS|INSTANCE|JOB|LANG|LANGUAGE|LC_ADDRESS|LC_ALL|LC_IDENTIFICATION|LC_MEASUREMENT|LC_MONETARY|LC_NAME|LC_NUMERIC|LC_PAPER|LC_TELEPHONE|LC_TIME|LESSCLOSE|LESSOPEN|LINES|LOGNAME|LS_COLORS|MACHTYPE|MAILCHECK|MANDATORY_PATH|NO_AT_BRIDGE|OLDPWD|OPTERR|OPTIND|ORBIT_SOCKETDIR|OSTYPE|PAPERSIZE|PATH|PIPESTATUS|PPID|PS1|PS2|PS3|PS4|PWD|RANDOM|REPLY|SECONDS|SELINUX_INIT|SESSION|SESSIONTYPE|SESSION_MANAGER|SHELL|SHELLOPTS|SHLVL|SSH_AUTH_SOCK|TERM|UID|UPSTART_EVENTS|UPSTART_INSTANCE|UPSTART_JOB|UPSTART_SESSION|USER|WINDOWID|XAUTHORITY|XDG_CONFIG_DIRS|XDG_CURRENT_DESKTOP|XDG_DATA_DIRS|XDG_GREETER_DATA_DIR|XDG_MENU_PREFIX|XDG_RUNTIME_DIR|XDG_SEAT|XDG_SEAT_PATH|XDG_SESSION_DESKTOP|XDG_SESSION_ID|XDG_SESSION_PATH|XDG_SESSION_TYPE|XDG_VTNR|XMODIFIERS)\\b"),
      lookbehind: true,
      alias: "constant"),
]);

final Grammar _g2 = Grammar([
  GrammarToken(
      "bash", compileHighlightPattern("(^([\"']?)\\w+\\2)[ \\t]+\\S.*"),
      lookbehind: true, alias: "punctuation", inside: () => _g0),
  GrammarToken(
      "environment",
      compileHighlightPattern(
          "\\\$\\b(?:BASH|BASHOPTS|BASH_ALIASES|BASH_ARGC|BASH_ARGV|BASH_CMDS|BASH_COMPLETION_COMPAT_DIR|BASH_LINENO|BASH_REMATCH|BASH_SOURCE|BASH_VERSINFO|BASH_VERSION|COLORTERM|COLUMNS|COMP_WORDBREAKS|DBUS_SESSION_BUS_ADDRESS|DEFAULTS_PATH|DESKTOP_SESSION|DIRSTACK|DISPLAY|EUID|GDMSESSION|GDM_LANG|GNOME_KEYRING_CONTROL|GNOME_KEYRING_PID|GPG_AGENT_INFO|GROUPS|HISTCONTROL|HISTFILE|HISTFILESIZE|HISTSIZE|HOME|HOSTNAME|HOSTTYPE|IFS|INSTANCE|JOB|LANG|LANGUAGE|LC_ADDRESS|LC_ALL|LC_IDENTIFICATION|LC_MEASUREMENT|LC_MONETARY|LC_NAME|LC_NUMERIC|LC_PAPER|LC_TELEPHONE|LC_TIME|LESSCLOSE|LESSOPEN|LINES|LOGNAME|LS_COLORS|MACHTYPE|MAILCHECK|MANDATORY_PATH|NO_AT_BRIDGE|OLDPWD|OPTERR|OPTIND|ORBIT_SOCKETDIR|OSTYPE|PAPERSIZE|PATH|PIPESTATUS|PPID|PS1|PS2|PS3|PS4|PWD|RANDOM|REPLY|SECONDS|SELINUX_INIT|SESSION|SESSIONTYPE|SESSION_MANAGER|SHELL|SHELLOPTS|SHLVL|SSH_AUTH_SOCK|TERM|UID|UPSTART_EVENTS|UPSTART_INSTANCE|UPSTART_JOB|UPSTART_SESSION|USER|WINDOWID|XAUTHORITY|XDG_CONFIG_DIRS|XDG_CURRENT_DESKTOP|XDG_DATA_DIRS|XDG_GREETER_DATA_DIR|XDG_MENU_PREFIX|XDG_RUNTIME_DIR|XDG_SEAT|XDG_SEAT_PATH|XDG_SESSION_DESKTOP|XDG_SESSION_ID|XDG_SESSION_PATH|XDG_SESSION_TYPE|XDG_VTNR|XMODIFIERS)\\b"),
      alias: "constant"),
  GrammarToken(
      "variable", compileHighlightPattern("\\\$?\\(\\([\\s\\S]+?\\)\\)"),
      greedy: true, inside: () => _g3),
  GrammarToken("variable",
      compileHighlightPattern("\\\$\\((?:\\([^)]+\\)|[^()])+\\)|`[^`]+`"),
      greedy: true, inside: () => _g4),
  GrammarToken("variable", compileHighlightPattern("\\\$\\{[^}]+\\}"),
      greedy: true, inside: () => _g8),
  GrammarToken("variable", compileHighlightPattern("\\\$(?:\\w+|[#?*!@\$])")),
  GrammarToken(
      "entity",
      compileHighlightPattern(
          "\\\\(?:[abceEfnrtv\\\\\"]|O?[0-7]{1,3}|U[0-9a-fA-F]{8}|u[0-9a-fA-F]{4}|x[0-9a-fA-F]{1,2})")),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "variable", compileHighlightPattern("(^\\\$\\(\\([\\s\\S]+)\\)\\)"),
      lookbehind: true),
  GrammarToken("variable", compileHighlightPattern("^\\\$\\(\\(")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x[\\dA-Fa-f]+\\b|(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:[Ee]-?\\d+)?")),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "--|\\+\\+|\\*\\*=?|<<=?|>>=?|&&|\\|\\||[=!+\\-*/%<>^&|]=?|[?~:]")),
  GrammarToken("punctuation", compileHighlightPattern("\\(\\(?|\\)\\)?|,|;")),
]);

final Grammar _g4 = Grammar([
  GrammarToken("variable", compileHighlightPattern("^\\\$\\(|^`|\\)\$|`\$")),
  GrammarToken("comment", compileHighlightPattern("(^|[^\"{\\\\\$])#.*"),
      lookbehind: true),
  GrammarToken(
      "function-name",
      compileHighlightPattern(
          "(\\bfunction\\s+)[\\w-]+(?=(?:\\s*\\(?:\\s*\\))?\\s*\\{)"),
      lookbehind: true,
      alias: "function"),
  GrammarToken("function-name",
      compileHighlightPattern("\\b[\\w-]+(?=\\s*\\(\\s*\\)\\s*\\{)"),
      alias: "function"),
  GrammarToken("for-or-select",
      compileHighlightPattern("(\\b(?:for|select)\\s+)\\w+(?=\\s+in\\s)"),
      lookbehind: true, alias: "variable"),
  GrammarToken("assign-left",
      compileHighlightPattern("(^|[\\s;|&]|[<>]\\()\\w+(?:\\.\\w+)*(?=\\+?=)"),
      lookbehind: true, alias: "variable", inside: () => _g1),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(^|\\s)-{1,2}(?:\\w+:[+-]?)?\\w+(?:\\.\\w+)*(?=[=\\s]|\$)"),
      lookbehind: true,
      alias: "variable"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "((?:^|[^<])<<-?\\s*)(\\w+)\\s[\\s\\S]*?(?:\\r?\\n|\\r)\\2"),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "((?:^|[^<])<<-?\\s*)([\"'])(\\w+)\\2\\s[\\s\\S]*?(?:\\r?\\n|\\r)\\3"),
      lookbehind: true,
      greedy: true,
      inside: () => _g5),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(^|[^\\\\](?:\\\\\\\\)*)\"(?:\\\\[\\s\\S]|\\\$\\([^)]+\\)|\\\$(?!\\()|`[^`]+`|[^\"\\\\`\$])*\""),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("(^|[^\$\\\\])'[^']*'"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string", compileHighlightPattern("\\\$'(?:[^'\\\\]|\\\\[\\s\\S])*'"),
      greedy: true, inside: () => _g6),
  GrammarToken(
      "environment",
      compileHighlightPattern(
          "\\\$?\\b(?:BASH|BASHOPTS|BASH_ALIASES|BASH_ARGC|BASH_ARGV|BASH_CMDS|BASH_COMPLETION_COMPAT_DIR|BASH_LINENO|BASH_REMATCH|BASH_SOURCE|BASH_VERSINFO|BASH_VERSION|COLORTERM|COLUMNS|COMP_WORDBREAKS|DBUS_SESSION_BUS_ADDRESS|DEFAULTS_PATH|DESKTOP_SESSION|DIRSTACK|DISPLAY|EUID|GDMSESSION|GDM_LANG|GNOME_KEYRING_CONTROL|GNOME_KEYRING_PID|GPG_AGENT_INFO|GROUPS|HISTCONTROL|HISTFILE|HISTFILESIZE|HISTSIZE|HOME|HOSTNAME|HOSTTYPE|IFS|INSTANCE|JOB|LANG|LANGUAGE|LC_ADDRESS|LC_ALL|LC_IDENTIFICATION|LC_MEASUREMENT|LC_MONETARY|LC_NAME|LC_NUMERIC|LC_PAPER|LC_TELEPHONE|LC_TIME|LESSCLOSE|LESSOPEN|LINES|LOGNAME|LS_COLORS|MACHTYPE|MAILCHECK|MANDATORY_PATH|NO_AT_BRIDGE|OLDPWD|OPTERR|OPTIND|ORBIT_SOCKETDIR|OSTYPE|PAPERSIZE|PATH|PIPESTATUS|PPID|PS1|PS2|PS3|PS4|PWD|RANDOM|REPLY|SECONDS|SELINUX_INIT|SESSION|SESSIONTYPE|SESSION_MANAGER|SHELL|SHELLOPTS|SHLVL|SSH_AUTH_SOCK|TERM|UID|UPSTART_EVENTS|UPSTART_INSTANCE|UPSTART_JOB|UPSTART_SESSION|USER|WINDOWID|XAUTHORITY|XDG_CONFIG_DIRS|XDG_CURRENT_DESKTOP|XDG_DATA_DIRS|XDG_GREETER_DATA_DIR|XDG_MENU_PREFIX|XDG_RUNTIME_DIR|XDG_SEAT|XDG_SEAT_PATH|XDG_SESSION_DESKTOP|XDG_SESSION_ID|XDG_SESSION_PATH|XDG_SESSION_TYPE|XDG_VTNR|XMODIFIERS)\\b"),
      alias: "constant"),
  GrammarToken(
      "function",
      compileHighlightPattern(
          "(^|[\\s;|&]|[<>]\\()(?:add|apropos|apt|apt-cache|apt-get|aptitude|aspell|automysqlbackup|awk|basename|bash|bc|bconsole|bg|bzip2|cal|cargo|cat|cfdisk|chgrp|chkconfig|chmod|chown|chroot|cksum|clear|cmp|column|comm|composer|cp|cron|crontab|csplit|curl|cut|date|dc|dd|ddrescue|debootstrap|df|diff|diff3|dig|dir|dircolors|dirname|dirs|dmesg|docker|docker-compose|du|egrep|eject|env|ethtool|expand|expect|expr|fdformat|fdisk|fg|fgrep|file|find|fmt|fold|format|free|fsck|ftp|fuser|gawk|git|gparted|grep|groupadd|groupdel|groupmod|groups|grub-mkconfig|gzip|halt|head|hg|history|host|hostname|htop|iconv|id|ifconfig|ifdown|ifup|import|install|ip|java|jobs|join|kill|killall|less|link|ln|locate|logname|logrotate|look|lpc|lpr|lprint|lprintd|lprintq|lprm|ls|lsof|lynx|make|man|mc|mdadm|mkconfig|mkdir|mke2fs|mkfifo|mkfs|mkisofs|mknod|mkswap|mmv|more|most|mount|mtools|mtr|mutt|mv|nano|nc|netstat|nice|nl|node|nohup|notify-send|npm|nslookup|op|open|parted|passwd|paste|pathchk|ping|pkill|pnpm|podman|podman-compose|popd|pr|printcap|printenv|ps|pushd|pv|quota|quotacheck|quotactl|ram|rar|rcp|reboot|remsync|rename|renice|rev|rm|rmdir|rpm|rsync|scp|screen|sdiff|sed|sendmail|seq|service|sftp|sh|shellcheck|shuf|shutdown|sleep|slocate|sort|split|ssh|stat|strace|su|sudo|sum|suspend|swapon|sync|sysctl|tac|tail|tar|tee|time|timeout|top|touch|tr|traceroute|tsort|tty|umount|uname|unexpand|uniq|units|unrar|unshar|unzip|update-grub|uptime|useradd|userdel|usermod|users|uudecode|uuencode|v|vcpkg|vdir|vi|vim|virsh|vmstat|wait|watch|wc|wget|whereis|which|who|whoami|write|xargs|xdg-open|yarn|yes|zenity|zip|zsh|zypper)(?=\$|[)\\s;|&])"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^|[\\s;|&]|[<>]\\()(?:case|do|done|elif|else|esac|fi|for|function|if|in|select|then|until|while)(?=\$|[)\\s;|&])"),
      lookbehind: true),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "(^|[\\s;|&]|[<>]\\()(?:\\.|:|alias|bind|break|builtin|caller|cd|command|continue|declare|echo|enable|eval|exec|exit|export|getopts|hash|help|let|local|logout|mapfile|printf|pwd|read|readarray|readonly|return|set|shift|shopt|source|test|times|trap|type|typeset|ulimit|umask|unalias|unset)(?=\$|[)\\s;|&])"),
      lookbehind: true,
      alias: "class-name"),
  GrammarToken(
      "boolean",
      compileHighlightPattern(
          "(^|[\\s;|&]|[<>]\\()(?:false|true)(?=\$|[)\\s;|&])"),
      lookbehind: true),
  GrammarToken("file-descriptor", compileHighlightPattern("\\B&\\d\\b"),
      alias: "important"),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "\\d?<>|>\\||\\+=|=[=~]?|!=?|<<[<-]?|[&\\d]?>>|\\d[<>]&?|[<>][&=]?|&[>&]?|\\|[&|]?"),
      inside: () => _g7),
  GrammarToken("punctuation",
      compileHighlightPattern("\\\$?\\(\\(?|\\)\\)?|\\.\\.|[{}[\\];\\\\]")),
  GrammarToken("number",
      compileHighlightPattern("(^|\\s)(?:[1-9]\\d*|0)(?:[.,]\\d+)?\\b"),
      lookbehind: true),
]);

final Grammar _g5 = Grammar([
  GrammarToken(
      "bash", compileHighlightPattern("(^([\"']?)\\w+\\2)[ \\t]+\\S.*"),
      lookbehind: true, alias: "punctuation", inside: () => _g0),
]);

final Grammar _g6 = Grammar([
  GrammarToken(
      "entity",
      compileHighlightPattern(
          "\\\\(?:[abceEfnrtv\\\\\"]|O?[0-7]{1,3}|U[0-9a-fA-F]{8}|u[0-9a-fA-F]{4}|x[0-9a-fA-F]{1,2})")),
]);

final Grammar _g7 = Grammar([
  GrammarToken("file-descriptor", compileHighlightPattern("^\\d"),
      alias: "important"),
]);

final Grammar _g8 = Grammar([
  GrammarToken("operator",
      compileHighlightPattern(":[-=?+]?|[!\\/]|##?|%%?|\\^\\^?|,,?")),
  GrammarToken("punctuation", compileHighlightPattern("[\\[\\]]")),
  GrammarToken(
      "environment",
      compileHighlightPattern(
          "(\\{)\\b(?:BASH|BASHOPTS|BASH_ALIASES|BASH_ARGC|BASH_ARGV|BASH_CMDS|BASH_COMPLETION_COMPAT_DIR|BASH_LINENO|BASH_REMATCH|BASH_SOURCE|BASH_VERSINFO|BASH_VERSION|COLORTERM|COLUMNS|COMP_WORDBREAKS|DBUS_SESSION_BUS_ADDRESS|DEFAULTS_PATH|DESKTOP_SESSION|DIRSTACK|DISPLAY|EUID|GDMSESSION|GDM_LANG|GNOME_KEYRING_CONTROL|GNOME_KEYRING_PID|GPG_AGENT_INFO|GROUPS|HISTCONTROL|HISTFILE|HISTFILESIZE|HISTSIZE|HOME|HOSTNAME|HOSTTYPE|IFS|INSTANCE|JOB|LANG|LANGUAGE|LC_ADDRESS|LC_ALL|LC_IDENTIFICATION|LC_MEASUREMENT|LC_MONETARY|LC_NAME|LC_NUMERIC|LC_PAPER|LC_TELEPHONE|LC_TIME|LESSCLOSE|LESSOPEN|LINES|LOGNAME|LS_COLORS|MACHTYPE|MAILCHECK|MANDATORY_PATH|NO_AT_BRIDGE|OLDPWD|OPTERR|OPTIND|ORBIT_SOCKETDIR|OSTYPE|PAPERSIZE|PATH|PIPESTATUS|PPID|PS1|PS2|PS3|PS4|PWD|RANDOM|REPLY|SECONDS|SELINUX_INIT|SESSION|SESSIONTYPE|SESSION_MANAGER|SHELL|SHELLOPTS|SHLVL|SSH_AUTH_SOCK|TERM|UID|UPSTART_EVENTS|UPSTART_INSTANCE|UPSTART_JOB|UPSTART_SESSION|USER|WINDOWID|XAUTHORITY|XDG_CONFIG_DIRS|XDG_CURRENT_DESKTOP|XDG_DATA_DIRS|XDG_GREETER_DATA_DIR|XDG_MENU_PREFIX|XDG_RUNTIME_DIR|XDG_SEAT|XDG_SEAT_PATH|XDG_SESSION_DESKTOP|XDG_SESSION_ID|XDG_SESSION_PATH|XDG_SESSION_TYPE|XDG_VTNR|XMODIFIERS)\\b"),
      lookbehind: true,
      alias: "constant"),
]);
