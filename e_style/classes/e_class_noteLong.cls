% =================================================================
% e_class_noteLong.cls
% A LaTeX class for long-form lecture notes (book-based).
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_noteLong}[Lecture Notes Class]

% --- Class Options ---

% The \makeatletter and \makeatother must wrap the entire block
% where commands with "@" are defined and used.
\makeatletter

% 12pt switch
\newif\if@e@twelvept
\@e@twelveptfalse

% Legacy CJK options are accepted but no-op in 2026 refactor.
% Glyph-level CJK support:  \usepackage{c112_langfamily} + \newlangfamily
% Full CJK layout engine:   \usepackage{c113_cjk_engine}
\DeclareOption{cjk}{\ClassWarning{e_class_noteLong}{%
    The [cjk] option is deprecated.\MessageBreak
    Use \string\usepackage{c113_cjk_engine} in the document preamble%
    \MessageBreak for full CJK layout, or \string\usepackage{c112_langfamily}%
    \MessageBreak for lightweight per-script glyph rendering}}
\DeclareOption{nocjk}{}

% When the '12pt' option is found, pass it to the base class
\DeclareOption{12pt}{
    \PassOptionsToClass{\CurrentOption}{book}
    \@e@twelvepttrue
}

% Pass unknown options to base class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}

\ProcessOptions\relax
\LoadClass{book}

\makeatother


\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_formal}
\RequirePackage{e_title_fenced_chap}
\RequirePackage{e_math_env_deco}

\pagestyle{plain}

\endinput
