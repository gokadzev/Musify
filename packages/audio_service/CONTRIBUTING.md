# Contributing to audio_service

Thank you for your interest in contributing!

Contributors not only contribute code but also help by submitting issues, contributing to issue discussions and helping to answer questions on StackOverflow.

This document outlines the rules and procedures when contributing.

## How we use GitHub

We use GitHub as a place and tool for contributors to work together on project development. That is, we use it to report bugs, suggest improvements, and contribute code and documentation to address those bugs or suggestions. It is not used as the place to ask for help (For that we use StackOverflow via the [audio-service](https://stackoverflow.com/questions/tagged/audio-service) tag).

## Reporting a bug

1. **Is it a bug?** Check first that you're using the API correctly according to the documentation (README and API documentation). If the API crashes when used incorrectly, you should not report a bug.
2. **Is it a new bug?** Search the GitHub issues page for bugs. If this bug has already been reported, you should not report a new bug.
3. **How can we reproduce it?** Fork this repository and make the "minimal" changes necessary to the example to reproduce the bug. This step is unnecessary if you choose to fix the bug yourself, or if the example already exhibits the bug without modification.
4. **Submit a report!** With all of the information you have collected you can submit a bug report via the "New issue" page on GitHub. It is necessary to fill in all required information in the form.

Things to AVOID:

* Do not share your whole app as the minimal reproduction project. This is not "minimal" and it makes it difficult to understand what's happening.
* Do not use a bug report to ask a question. Use StackOverflow instead.
* Do not submit a bug report if you are not using the APIs correctly according to the documentation.
* Try to avoid posting a duplicate bug.
* Do not ignore the instructions within the form.

## Suggesting an improvement

The GitHub "New issue" page also allows you to contribute feature proposals and documentation suggestions. As with bugs, you should always familiarise yourself with the existing API documentation before suggesting an improvement, and search the issues database to see if your improvement has already been suggested.

Feature proposals should be genuine proposals, not questions or requests for help.

Documentation suggestions should also be concrete suggestions identifying a specific page and section to improve, not questions or requests for help.

## Making a pull request

Pull requests are used to contribute bug fixes, new features or documentation improvements. Before working on a pull request, an issue should exist that describes the feature or bug.

To create a pull request:

1. Fork this repository
2. Create a branch for your changes. Branch off the `major` branch if introducing a breaking change that is not backwards compatible, or instead off the `minor` branch if making a non-breaking change or bug fix.
3. Make your changes, updating the documentation if you have changed any API's behaviour.
4. If you are the first to contribute to the next version, increment the version number in `pubspec.yaml` according to the [pub versioning philosophy](https://dart.dev/tools/pub/versioning).
5. Add a description of your change to `CHANGELOG.md` (format: `* DESCRIPTION OF YOUR CHANGE (@your-git-username)`).
6. Run `flutter analyze` to ensure your code meets the static analysis requirements.
7. Run `flutter test` to ensure all unit tests continue to work (Please consider also contributing unit tests covering your new code).
8. Create the pull request via [GitHub's instructions](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork).
9. [link](https://docs.github.com/en/github/managing-your-work-on-github/linking-a-pull-request-to-an-issue) that pull request with the original issue.

Best practices for a pull request:

* Follow the style of existing code, paying attention to whitespace and formatting. (In Dart, we use `dart format` which may already be integrated into your IDE.)
* Check your diffs prior to submission. Try to make your pull request diff reflect only the lines of code that needed to be changed to address the issue at hand. If your diff also changes other things, such as by making superficial changes to code formatting and layout, or checking in superfluous files such as your IDE or other config files, please remove them so that your diff focus on the essential. That helps keep the commit history clean and also makes your pull request easier to review.
* Try not to introduce multiple unrelated changes in a single pull request. Create individual pull requests so that they can be evaluated and accepted independently.
* Use meaningful commit messages so that your changes can be more easily browsed and referenced.
