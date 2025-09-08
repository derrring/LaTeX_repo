%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CV Espresso Deedy Class - 1 Column
%
% Based on the original Deedy Resume 1-Column template
% Refactored into .sty + .cls architecture
%
% Author: Based on Deedy Resume template
% License: MIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{cv_espresso_deedy_1col}[2025/08/29 CV Espresso Deedy class - 1 Column version]

% Handle class options
\DeclareOption{print}{\def\@cv@print{}}
\DeclareOption{a4}{\PassOptionsToPackage{a4}{cv_espresso_deedy_common}}
\DeclareOption{a4paper}{\PassOptionsToPackage{a4paper}{cv_espresso_deedy_common}}
\DeclareOption{letter}{\PassOptionsToPackage{letter}{cv_espresso_deedy_common}}
\DeclareOption{letterpaper}{\PassOptionsToPackage{letterpaper}{cv_espresso_deedy_common}}
\DeclareOption*{
  \PassOptionsToClass{\CurrentOption}{article}%
}
\ProcessOptions\relax

% Class identifier for conditional behavior
\def\@cv@onecol{}

% Load base article class
\LoadClass{article}

% Load common CV functionality
\RequirePackage{cv_espresso_deedy_common}

% 1-Column specific packages
\RequirePackage{enumitem}
\RequirePackage{tabularx}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1-COLUMN SPECIFIC COMMANDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define cvtext for 1-column layout (works with itemize)
\newcommand{\cvtext}[4]{%
  \cvrunsubsection{#1}
  \cvdescript{#2}
  \cvlocation{#3}
  \ifstrempty{#4}{}{%
    \vspace{1pt}%
    #4%
  }%
}

% Define cventry for 1-column layout (no automatic \item)
\newcommand{\cventry}[4]{%
  \cvrunsubsection{#1}
  \cvdescript{#2}
  \cvlocation{#3}
  \ifstrempty{#4}{}{%
    \vspace{-4pt}%
    \begin{cvitemlist}%
      #4%
    \end{cvitemlist}%
  }%
  \vspace{1pt}
}

% New tabular-based entry command (no \item inside definition)
% Parameters: #1=Company/Institution, #2=Location, #3=Position/Degree, #4=Date
  \newcommand{\cvtabentry}[4]{%
    \raisebox{1.5ex}{%
    \begin{minipage}[t]{0.55\linewidth}
        \color{subheadings}\cvsubheadingfont\fontsize{12pt}{12pt}\selectfont{\scshape #1}%
        \ifboolexpr{not test {\ifblank{#3}} or not test {\ifblank{#4}}}{ \\
  \color{subheadings}\cvdescfont\fontsize{11pt}{13pt}\selectfont{\textit{#3}}}{}
      \end{minipage}%
      \hfill%
      \begin{minipage}[t]{0.45\linewidth}
        \raggedleft%
        \color{headings}\cvlocationfont\fontsize{10pt}{12pt}\selectfont #2%
        \ifboolexpr{not test {\ifblank{#3}} or not test {\ifblank{#4}}}{ \\
  \color{headings}\cvlocationfont\fontsize{10pt}{12pt}\selectfont{\textit{#4}}}{}
      \end{minipage}%
    }
    }




%\topsep = vertical space added above and below the list.
%\partopsep = vertical space added above and below the list, but only if the list starts a new paragraph.


\newenvironment{cventrylist}
  {\begin{itemize}[leftmargin=*,itemsep={\cvsubsectionskip},parsep=2pt,topsep=0pt,partopsep=0pt]}
  {\end{itemize}}

\newenvironment{cvitemlist}
  {\begin{itemize}[leftmargin=*,itemsep=1pt,parsep=1pt,topsep=0pt,partopsep=0pt]}
  {\end{itemize}}