
# LaTeX_dynamic

Programming in $\LaTeX 3$. Motivated by 


1. Fixed template of function definition:
$$
        N: \left\{\begin{array}{ccc}
            H&\to&\mathbb{R}^+\\
            x&\mapsto&\lVert x\rVert\\
            
        \end{array}\right.
$$
```latex
 \begin{equation*}
        N: \left\{\begin{array}{ccc}
            H&\to&\mathbb{R}^+\\
            x&\mapsto&\norm{x}\\
            
        \end{array}\right.
    \end{equation*}
```
we may abstract a environment or function to gain generality.

2. Optional argument in `\newcommand` or `\def`

```latex
\newcommand{\norm}[1]{\left\Vert #1 \right\Vert}
```

but with various kinds of norms, $\lVert f\rVert_{C^k(\overline{\Omega})}$, $\lVert f\rVert_{W^{n,p}}$,  $\lVert x\rVert_{\mathcal{L}(E,F)}$, it would be more propre to add an optional argument to present the subscription as `\norm[]{}`.


3. Calculation and control flow in $\LaTeX_{2\varepsilon}$