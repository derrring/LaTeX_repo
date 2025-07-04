% =================================================================
% e_class_notes.cls
% A LaTeX class for lecture notes, based on user-provided style files.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_noteLong}[Lecture Notes Class]

% --- Class Options ---
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}  
\DeclareOption{12pt}{%
    \PassOptionsToClass{\CurrentOption}{book}
    \AtEndOfClass{%
        % Mimic 11pt class section sizes exactly
        \titleformat{\section}
            {\fontsize{14.4pt}{17.28pt}\selectfont\bfseries}{\thesection}{1em}{}
            % Exactly matches 11pt class \Large

        \titleformat{\subsection}
            {\fontsize{12pt}{14.4pt}\selectfont\bfseries}{\thesubsection}{1em}{}
            % Exactly matches 11pt class \large

        \titleformat{\subsubsection}
            {\fontsize{11pt}{13.2pt}\selectfont\bfseries}{\thesubsubsection}{1em}{}
            % Exactly matches 11pt class \normalsize
    }%
}

\ProcessOptions\relax
\LoadClass{book}


\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_formal}
\RequirePackage{e_title_fenced_chap}
\RequirePackage{e_math_env_deco}


\endinput