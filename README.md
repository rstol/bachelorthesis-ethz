# Bachelor Thesis by Romeo Stoll

The thesis is titled: "Boosting flexibility in coding exercises by building containers in real time" (ETH Zürich, Spring 2022)

## Thesis paper

The full version can be [read here](./BachelorThesisRomeoStoll.pdf).

### Abstract

At ETH Zürich, lecturers can use a software platform alled CodeExpert to set up environments for coding exercises every student can access using a browser. These development environments are commonly run inside containers on virtual machines. They are currently prebuilt in a long and manual process, which impedes configuration flexibility for the lecturer and makes maintainability a burden for the developer.
The aim is to find and evaluate feasible approaches that solve the challenges of the current approach by creating flexible environments at runtime. The new approach should limit security vulnerabilities and improve the developer experience. The potential build time overhead should not poorly impact the experience of students and lecturers. Fur- thermore, lecturers should be able to efficiently set up a development environment that includes any package and language.
This thesis proposes two approaches relying on the Nix build system that allows building environments at runtime. A prototype was built and evaluated for each approach, following the design and objectives advocated in this thesis. It is shown how the prototypes improve the user and developer experience compared to the current approach.
It is argued that one of our approaches provides the basis for the next version of environments at CodeExpert that will deliver better maintain- ability, offer more configuration flexibility and have a comparable or better build performance.

## Project structure

You can find the installation guides for both prototypes in the corresponding folders:

1. [**Build images at runtime**](./prototypes/build-image-at-runtime)
2. [**Nix-shell at runtime**](./prototypes/nix-shell-at-runtime)

```bash
├── BachelorThesisRomeoStoll.pdf
├── README.md
├── cxenv
│   ├── ...
├── presentations
│   ├── FinalPresentation.pptx
│   ├── FinalPresentationV2.pptx
│   ├── ...
├── prototypes
│   ├── build-image-at-runtime
│   │   ├── ...
│   ├── cxenv_benchmarks
│   │   ├── ...
│   ├── nix-shell-at-runtime
│   │   ├── ...
│   ├── plot-compare-approaches
│   │   ├── ...
│   └── plotting.py
├── research
│   ├── RuntimeContainerBuild.pdf
│   ├── content
│   │   └── literatureNotes.txt
│   └── graphics
│       ├── ...
└── thesis
    ├── ...
```
