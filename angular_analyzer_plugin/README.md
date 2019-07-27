[![pub package](https://img.shields.io/pub/v/angular_analyzer_plugin.svg)](https://pub.dev/packages/angular_analyzer_plugin)

**Requires angular-5.0.0\* and dart SDK 2.0.0-dev.31\*\* or higher to work.**

\* Works with angular-4.0.0 by following the steps in the section "loading an exact version."

\*\* Linux and Mac users should be able to an SDK version as old as 1.25.0-dev.12.0

## Integration with Dart Analysis Server

  To provide information for DAS clients the `server_plugin` plugin contributes several extensions.

* Angular analysis errors are automatically merged into normal `errors` notifications for Dart and HTML files.

## Installing By Angular Version -- For Angular Developers (recommended)

Using this strategy allows the dart ecosystem to discover which version of our plugin will work best with your version of angular, and therefore is recommended.

Simply add to your [analysis_options.yaml file](https://www.dartlang.org/guides/language/analysis-options#the-analysis-options-file):

```yaml
analyzer:
  plugins:
    - angular
```

Then simply reboot your analysis server (inside IntelliJ this is done by clicking on the skull icon if it exists, or the refresh icon otherwise) and wait for the plugin to fully load, which can take a minute on the first run.

The plugin will self-upgrade if you update angular. Otherwise, you can get any version of the plugin you wish by following the steps in the next section.

## Loading an Exact Version

This is much like the previous step. However, you should include this project in your pubspec:

```yaml
dependencies:
  angular_analyzer_plugin: 0.0.13
```

and then load the plugin as itself, rather than as a dependency of angular:

```yaml
analyzer:
  plugins:
    - angular_analyzer_plugin
```

Like the previous installation option, you then just need to reboot your analysis server after running pub get.

## Troubleshooting

If you have any issues, filing an issue with us is always a welcome option. There are a few things you can try on your own, as well, to get an idea of what's going wrong:

* Are you using angular 5 or newer? If not, are you loading a recent exact version of the plugin?
* Are you using a bleeding edge SDK? The latest stable will not work correctly, and windows users require at least 2.0.0-dev-31.
* Did you turn the plugin on correctly in your analysis options file?
* From IntelliJ in the Dart Analysis panel, there's a gear icon that has "analyzer diagnostics," which opens a web page that has a section for loaded plugins. Are there any errors?
* Does your editor support html+dart analysis, or is it an old version? Some (such as VSCode, vim) may have special steps to show errors surfaced by dart analysis inside your html files.
* Check the directory `~/.dartServer/.plugin_manager` (on Windows: `\Users\you\AppData\Local\.dartServer\.plugin_manager`). Does it have any subdirectories?
* There should be a hash representing each plugin you've loaded. Can you run `pub get` from `HASH/analyzer_plugin`? (If you have multiple hashes, it should be safe to clear this directory & reload.)
* If you run `bin/plugin.dart` from `.plugin_manager/HASH/analyzer_plugin`, do you get any import errors? (Note: this is expected to crash when launched in this way, but without import-related errors)

We may ask you any or all of these questions if you open an issue, so feel free to go run through these checks on your own to get a hint what might be wrong.

## Upgrading

Any Dart users on 2.0.0-dev.48 or newer will get updates on every restart of the analysis server. If you are on an older Dart version than that, check the Troubleshooting section.

## Building -- For hacking on this plugin, or using the latest unpublished.

There's an `pubspec.yaml` file that needs to be updated to point to your local system:

```console
$ cd angular_analyzer_plugin/tools/analyzer_plugin
$ cp pubspec.yaml.defaults pubspec.yaml
```

Modify `pubspec.yaml` in this folder to fix the absolute paths. They **must** be absolute!

Then run `pub get`.

You can now use this in projects on your local system which a correctly configured pubspec and analysis options. For instance, `playground/`. Note that it imports the plugin by path, and imports it as a plugin inside `analysis_options.yaml`.

## What's supported

For what's currently supported, see `CURRENT_SUPPORT.md`.
