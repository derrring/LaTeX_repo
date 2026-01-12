% =================================================================
% e_class_notes.cls
% A LaTeX class for thesis, based on user-provided style files.
% Version 1.0
% =================================================================


\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_thesis}[Thesis Class]

% --- Class Options ---

% Define a new switch to check if the 12pt option was used.
% The \makeatletter and \makeatother must wrap the entire block
% where commands with "@" are defined and used.
\makeatletter
\newif\if@e@twelvept
\@e@twelveptfalse % Initialize the switch to false

% Process options passed to the class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}

% When the '12pt' option is found, pass it to the base class
% and set our custom switch to true.
\DeclareOption{12pt}{%
    \PassOptionsToClass{\CurrentOption}{book}
    \@e@twelvepttrue
}

\ProcessOptions\relax
\LoadClass{book}

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
% --- 2. Load the common style package ---
% This single command loads all your modular style components (packages, commands, colors, etc.).
\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_formal} % Load the front and back matter package
\RequirePackage{e_title_caligraphy_chap}


% --- 3. Define user-facing commands for thesis metadata ---


% --- 4. Define commands and environments for document structure ---




% --- 5. Define Thesis-specific Formatting ---
% This section contains styling for chapters and ToC from general.tex
\linespread{1.1}



% Override only for 12pt option


%-----------------------------------------------------------------------


\endinput
