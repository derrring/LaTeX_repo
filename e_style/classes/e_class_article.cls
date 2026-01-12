% =================================================================
% e_class_article.cls
% A LaTeX class for articles, based on user-provided style files.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_article}[Article Class]

% --- Class Options ---

% The \makeatletter and \makeatother must wrap the entire block
% where commands with "@" are defined and used.
\makeatletter

% CJK switch - must be defined BEFORE loading packages
\newif\ifcjk
\cjkfalse % Default to CJK support DISABLED

% 12pt switch
\newif\if@e@twelvept
\@e@twelveptfalse

% Declare CJK options
\DeclareOption{cjk}{\cjktrue}
\DeclareOption{nocjk}{\cjkfalse}

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

% --- 2. Load the common style package ---
\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_simple}

% --- 3. Article-specific Formatting ---
\linespread{1.1}

\endinput
