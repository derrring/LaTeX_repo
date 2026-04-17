% =================================================================
% e_class_noteShort.cls
% A LaTeX class for short notes with decorated math environments.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_noteShort}[Article Class]

% --- Class Options ---

% The \makeatletter and \makeatother must wrap the entire block
% where commands with "@" are defined and used.
\makeatletter

% 12pt switch
\newif\if@e@twelvept
\@e@twelveptfalse

% Legacy CJK options are accepted but no-op in 2026 refactor.
\DeclareOption{cjk}{\ClassWarning{e_class_noteShort}{%
    The [cjk] option is deprecated.\MessageBreak
    Use \string\usepackage{c113_cjk_engine} in the document preamble%
    \MessageBreak for full CJK layout, or \string\usepackage{c112_langfamily}%
    \MessageBreak for lightweight per-script glyph rendering}}
\DeclareOption{nocjk}{}

% When the '12pt' option is found, pass it to the base class
\DeclareOption{12pt}{
    \PassOptionsToClass{\CurrentOption}{article}
    \@e@twelvepttrue
}

% Pass unknown options to base class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}

\ProcessOptions\relax
\LoadClass{article}

\makeatother


\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_simple}
\RequirePackage{e_title_fenced_sec}
\RequirePackage{e_math_env_deco}


\endinput
