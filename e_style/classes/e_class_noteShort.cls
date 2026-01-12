% =================================================================
% e_class_notes.cls
% A LaTeX class for article and reports, based on user-provided style files.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_noteShort}[Article Class]

% --- Class Options ---

% Define a new switch to check if the 12pt option was used.
% The \makeatletter and \makeatother must wrap the entire block
% where commands with "@" are defined and used.
\makeatletter
\newif\if@e@twelvept
\@e@twelveptfalse % Initialize the switch to false

% Process options passed to the class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}

% When the '12pt' option is found, pass it to the base class
% and set our custom switch to true.
\DeclareOption{12pt}{%
    \PassOptionsToClass{\CurrentOption}{article}
    \@e@twelvepttrue
}

\ProcessOptions\relax
\LoadClass{article}

% --- Delayed Font Size Adjustment ---
% This code runs right before the document begins, after all packages
% and title styles have been loaded.
\AtBeginDocument{%
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


\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_simple}
\RequirePackage{e_title_fenced_sec}
\RequirePackage{e_math_env_deco}


\endinput
