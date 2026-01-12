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

% --- Delayed Font Size Adjustment ---
% This code runs right before the document begins, after all packages
% and title styles have been loaded.
\AtBeginDocument+{%
    % Check if our 12pt switch is true
    \if@e@twelvept
        % If it is, apply the specific font sizes. This will now
        % correctly override the default sizes from other packages
        % without causing an option clash error.
        \titleformat{\section}
            {\fontsize{14.4pt}{17.28pt}\selectfont\bfseries}{\thesection}{1em}{}
        \titleformat{\subsection}
            {\fontsize{12pt}{14.4pt}\selectfont\bfseries}{\thesubsection}{1em}{}
        \titleformat{\subsubsection}
            {\fontsize{11pt}{13.2pt}\selectfont\bfseries}{\thesubsubsection}{1em}{}
    \fi
}
\makeatother

% --- 2. Load the common style package ---
\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_simple}

% --- 3. Article-specific Formatting ---
\linespread{1.1}

\endinput
