# MaterialTabs

This repository is a fork of this specific folder https://github.com/material-components/material-components-ios/tree/v54.10.0/components/Tabs, pinned at [v54.10.0](https://github.com/material-components/material-components-ios/releases/tag/v54.10.0).

## Why this package was needed

In the process of migrating our project to use only SPM, we had this dependency that [has no intentions of supporting SPM](https://github.com/material-components/material-components-ios/issues/7559#issuecomment-894375323). So this package was born with the intention to add SPM support to that dependency.

## How this package was created

Since `/Tabs` was the only component that we used from that dependency, this project simply copy and pasted the that folder, and all of its dependencies (which's scattered in other folders inside that repository, as well as in https://github.com/material-foundation/material-internationalization-ios). 

So during the process of creation of this package, we:

- Copy and pasted the source files of located here: https://github.com/material-components/material-components-ios/tree/v54.10.0/components/Tabs
- Flattened out entire file structure
- Copy and pasted all the missing dependencies from other folders within that same repository (always in the same tag), as well as from https://github.com/material-foundation/material-internationalization-ios

## Why v54.10.0?

Because it's the version that we've been using for all these years, had no issues, and migrating to the latest version would be a pain, take some time, be regression-prone, and there're no reasons to upgrade this UI-only lib.

## Maintenance

This package is currently not maintained by anyone, and we don't intend to maintain it (like upgrade it to the latest version of its parent repo, or migrate to Swift). However, if we need to apply any fixes to it, it can be done to this repo.
