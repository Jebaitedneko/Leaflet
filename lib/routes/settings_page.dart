import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:loggy/loggy.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:potato_notes/data/dao/note_helper.dart';
import 'package:potato_notes/data/database.dart';
import 'package:potato_notes/internal/locales/native_names.dart';
import 'package:potato_notes/internal/sync/note_controller.dart';
import 'package:potato_notes/internal/in_app_update.dart';
import 'package:potato_notes/internal/providers.dart';
import 'package:potato_notes/internal/utils.dart';
import 'package:potato_notes/internal/locales/locale_strings.g.dart';
import 'package:potato_notes/routes/about_page.dart';
import 'package:potato_notes/routes/base_page.dart';
import 'package:potato_notes/routes/backup_and_restore/import_page.dart';
import 'package:potato_notes/widget/dependent_scaffold.dart';
import 'package:potato_notes/widget/pass_challenge.dart';
import 'package:potato_notes/widget/rgb_color_picker.dart';
import 'package:potato_notes/widget/settings_category.dart';
import 'package:potato_notes/widget/settings_tile.dart';
import 'package:potato_notes/widget/sync_url_editor.dart';
import 'package:recase/recase.dart';

class SettingsPage extends StatefulWidget {
  final bool trimmed;

  SettingsPage({
    Key key,
    this.trimmed = false,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool removingMasterPass = false;

  @override
  Widget build(BuildContext context) {
    if (widget.trimmed) return Observer(builder: (context) => commonSettings);

    return DependentScaffold(
      resizeToAvoidBottomInset: false,
      body: Observer(builder: (context) {
        return ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          children: [
            commonSettings,
            SettingsCategory(
              header: "Backup & Restore",
              children: [
                SettingsTile(
                  icon: Icon(MdiIcons.contentSaveOutline),
                  title: Text("Backup"),
                  description: Text("Create a local copy of your notes"),
                  onTap: () {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "This feature is not yet available on this version."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                SettingsTile(
                  icon: Icon(MdiIcons.restore),
                  title: Text("Restore"),
                  description: Text(
                      "Restore a backup created from a version of Leaflet"),
                  onTap: () {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "This feature is not yet available on this version."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                SettingsTile(
                  icon: Icon(MdiIcons.fileImportOutline),
                  title: Text("Migrate"),
                  description:
                      Text("Import notes from a version of PotatoNotes"),
                  onTap: () async {
                    return Utils.showSecondaryRoute(
                      context,
                      ImportPage(),
                    );
                  },
                ),
              ],
            ),
            SettingsCategory(
              header: LocaleStrings.settingsPage.infoTitle,
              children: <Widget>[
                SettingsTile(
                  icon: Icon(Icons.info_outline),
                  title: Text(LocaleStrings.settingsPage.infoAboutApp),
                  onTap: () => Utils.showSecondaryRoute(
                    context,
                    AboutPage(),
                  ),
                ),
                SettingsTile(
                  icon: Icon(Icons.update_outlined),
                  title: Text("Check for app updates"),
                  onTap: () => InAppUpdater.checkForUpdate(
                    context,
                    showNoUpdatesAvailable: true,
                  ),
                ),
              ],
            ),
            Visibility(
              visible: kDebugMode,
              child: SettingsCategory(
                header: LocaleStrings.settingsPage.debugTitle,
                children: [
                  SettingsTile.withSwitch(
                    icon: Icon(MdiIcons.humanGreeting),
                    title: Text(
                      LocaleStrings.settingsPage.debugShowSetupScreen,
                    ),
                    value: !prefs.welcomePageSeen,
                    activeColor: Theme.of(context).accentColor,
                    onChanged: (value) async {
                      prefs.welcomePageSeen = !value;
                    },
                  ),
                  SettingsTile(
                    icon: Icon(MdiIcons.databaseRemoveOutline),
                    title: Text(LocaleStrings.settingsPage.debugClearDatabase),
                    onTap: () async {
                      await helper.deleteAllNotes();
                      await NoteController.deleteAll();
                    },
                  ),
                  SettingsTile(
                    icon: Icon(Icons.text_snippet_outlined),
                    title: Text(LocaleStrings.settingsPage.debugLogLevel),
                    onTap: () {
                      showDropdownSheet(
                        context: context,
                        itemBuilder: (context, index) {
                          bool selected =
                              prefs.logLevel == logEntryValues[index];

                          return dropDownTile(
                            selected: selected,
                            title: Text(
                              getLogEntryName(logEntryValues[index]),
                            ),
                            onTap: () {
                              prefs.logLevel = logEntryValues[index];
                              Navigator.pop(context);
                            },
                          );
                        },
                        itemCount: logEntryValues.length,
                      );
                    },
                    subtitle: Text(getLogEntryName(prefs.logLevel)),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget get commonSettings {
    final String currentLocaleName = firstLetterToUppercase(
      localeNativeNames[context.locale.languageCode],
    );

    return Column(
      children: <Widget>[
        SettingsCategory(
          header: LocaleStrings.settingsPage.personalizationTitle,
          children: [
            SettingsTile(
              icon: Icon(Icons.brightness_medium_outlined),
              title: Text(LocaleStrings.settingsPage.personalizationThemeMode),
              onTap: () {
                showDropdownSheet(
                  context: context,
                  itemBuilder: (context, index) {
                    bool selected = prefs.themeMode == ThemeMode.values[index];

                    return dropDownTile(
                      selected: selected,
                      title: Text(
                        getThemeModeName(ThemeMode.values[index]),
                      ),
                      onTap: () {
                        prefs.themeMode = ThemeMode.values[index];
                        Navigator.pop(context);
                      },
                    );
                  },
                  itemCount: ThemeMode.values.length,
                );
              },
              subtitle: Text(getThemeModeName(prefs.themeMode)),
            ),
            SettingsTile.withSwitch(
              value: prefs.useAmoled,
              onChanged: (value) => prefs.useAmoled = value,
              title: Text(LocaleStrings.settingsPage.personalizationUseAmoled),
              icon: Icon(Icons.brightness_2_outlined),
              activeColor: Theme.of(context).accentColor,
            ),
            if (deviceInfo.canUseSystemAccent)
              SettingsTile.withSwitch(
                value: !deviceInfo.canUseSystemAccent
                    ? false
                    : !prefs.useCustomAccent,
                onChanged: (value) => prefs.useCustomAccent = !value,
                title: Text(
                  LocaleStrings.settingsPage.personalizationUseCustomAccent,
                ),
                icon: Icon(Icons.color_lens_outlined),
                activeColor: Theme.of(context).accentColor,
              ),
            SettingsTile(
              title: Text(
                LocaleStrings.settingsPage.personalizationCustomAccent,
              ),
              icon: Icon(Icons.colorize_outlined),
              enabled: !deviceInfo.canUseSystemAccent || prefs.useCustomAccent,
              trailing: AnimatedOpacity(
                opacity: !deviceInfo.canUseSystemAccent || prefs.useCustomAccent
                    ? 1
                    : 0.5,
                duration: Duration(milliseconds: 200),
                child: SizedBox(
                  width: 60,
                  child: Icon(
                    Icons.brightness_1,
                    color: prefs.customAccent ?? Utils.defaultAccent,
                    size: 28,
                  ),
                ),
              ),
              onTap: () async {
                final int result = await Utils.showNotesModalBottomSheet(
                  context: context,
                  builder: (context) => RGBColorPicker(
                    initialColor: Theme.of(context).accentColor,
                  ),
                );

                if (result != null) {
                  if (result == -1) {
                    prefs.customAccent = null;
                  } else {
                    prefs.customAccent = Color(result);
                  }
                }
              },
            ),
            SettingsTile.withSwitch(
              value: prefs.useGrid,
              onChanged: (value) => prefs.useGrid = value,
              title: Text(LocaleStrings.settingsPage.personalizationUseGrid),
              icon: Icon(Icons.dashboard_outlined),
              activeColor: Theme.of(context).accentColor,
            ),
            SettingsTile(
              icon: Icon(Icons.translate),
              title: Text(LocaleStrings.settingsPage.personalizationLocale),
              onTap: () {
                showDropdownSheet(
                  context: context,
                  scrollable: true,
                  itemBuilder: (context, index) {
                    final Locale locale = context.supportedLocales[index];
                    final String nativeName = firstLetterToUppercase(
                      localeNativeNames[locale.languageCode],
                    );
                    final bool selected = context.locale == locale;

                    return dropDownTile(
                      title: Text(nativeName),
                      selected: selected,
                      onTap: () {
                        context.locale = locale;
                        Navigator.pop(context);
                      },
                    );
                  },
                  itemCount: context.supportedLocales.length,
                );
              },
              subtitle: Text(currentLocaleName),
            ),
            SettingsTile(
              icon: Icon(Icons.autorenew),
              title: Text("Change sync API url"),
              onTap: () async {
                final bool status = await showInfoSheet(
                  context,
                  content:
                      "If you decide to change the sync api url every note will get deleted to prevent conflicts. Do this only if you know what are you doing.",
                  buttonAction: LocaleStrings.common.goOn,
                );
                if (status)
                  Utils.showNotesModalBottomSheet(
                    context: context,
                    builder: (context) => SyncUrlEditor(),
                  );
              },
            )
          ],
        ),
        SettingsCategory(
          header: LocaleStrings.settingsPage.privacyTitle,
          children: [
            SettingsTile.withSwitch(
              value: prefs.masterPass != "",
              onChanged: (value) async {
                if (prefs.masterPass == "") {
                  final bool status = await showInfoSheet(
                    context,
                    content: LocaleStrings
                        .settingsPage.privacyUseMasterPassDisclaimer,
                    buttonAction: LocaleStrings.common.goOn,
                  );
                  if (status) showPassChallengeSheet(context);
                } else {
                  final bool confirm =
                      await showPassChallengeSheet(context, false) ?? false;

                  if (confirm) {
                    prefs.masterPass = "";

                    final List<Note> notes =
                        await helper.listNotes(ReturnMode.LOCAL);

                    setState(() => removingMasterPass = true);
                    BasePage.of(context).setBottomBarEnabled(false);
                    for (int i = 0; i < notes.length; i++) {
                      final Note note = notes[i];
                      if (note.lockNote) {
                        await helper.saveNote(
                          note.markChanged().copyWith(lockNote: false),
                        );
                      }
                    }
                    BasePage.of(context).setBottomBarEnabled(true);
                  }
                }
              },
              icon: Icon(Icons.vpn_key_outlined),
              title: Text(LocaleStrings.settingsPage.privacyUseMasterPass),
              activeColor: Theme.of(context).accentColor,
              subtitle: removingMasterPass ? LinearProgressIndicator() : null,
            ),
            SettingsTile(
              icon: Icon(MdiIcons.formTextboxPassword),
              title: Text(LocaleStrings.settingsPage.privacyModifyMasterPass),
              enabled: prefs.masterPass != "",
              onTap: () async {
                final bool confirm =
                    await showPassChallengeSheet(context, false) ?? false;
                if (confirm) showPassChallengeSheet(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> showInfoSheet(BuildContext context,
      {String content, String buttonAction}) async {
    return await Utils.showNotesModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(content),
              ),
              ListTile(
                leading: Icon(Icons.arrow_forward),
                title: Text(buttonAction),
                onTap: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<dynamic> showDropdownSheet({
    @required BuildContext context,
    @required IndexedWidgetBuilder itemBuilder,
    int itemCount,
    bool scrollable = false,
  }) async {
    final Widget list = ListView.builder(
      shrinkWrap: true,
      physics: scrollable ? null : NeverScrollableScrollPhysics(),
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      padding: EdgeInsets.all(0),
    );

    return await Utils.showNotesModalBottomSheet(
      context: context,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.shortestSide,
        ),
        child: list,
      ),
    );
  }

  Widget dropDownTile({
    @required Widget title,
    Widget subtitle,
    @required bool selected,
    VoidCallback onTap,
  }) {
    return ListTile(
      selected: selected,
      contentPadding: EdgeInsets.symmetric(horizontal: 24),
      title: title,
      subtitle: subtitle,
      trailing: selected ? Icon(Icons.check) : null,
      onTap: onTap,
    );
  }

  String getThemeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return LocaleStrings.settingsPage.personalizationThemeModeLight;
      case ThemeMode.dark:
        return LocaleStrings.settingsPage.personalizationThemeModeDark;
      case ThemeMode.system:
      default:
        return LocaleStrings.settingsPage.personalizationThemeModeSystem;
    }
  }

  Future<dynamic> showPassChallengeSheet(BuildContext context,
      [bool editMode = true]) async {
    return await Utils.showNotesModalBottomSheet(
      context: context,
      builder: (context) => PassChallenge(
        editMode: editMode,
        onChallengeSuccess: () => Navigator.pop(context, true),
        onSave: (text) async {
          prefs.masterPass = text;

          Navigator.pop(context);
        },
      ),
    );
  }

  String firstLetterToUppercase(String origin) {
    return ReCase(origin).sentenceCase;
  }

  List<int> get logEntryValues => [
        LogEntry.VERBOSE,
        LogEntry.DEBUG,
        LogEntry.INFO,
        LogEntry.WARN,
        LogEntry.ERROR,
        LogEntry.WTF,
      ];

  String getLogEntryName(int entry) {
    switch (entry) {
      case LogEntry.DEBUG:
        return "Debug";
      case LogEntry.INFO:
        return "Info";
      case LogEntry.WARN:
        return "Warn";
      case LogEntry.ERROR:
        return "Error";
      case LogEntry.WTF:
        return "WTF";
      case LogEntry.VERBOSE:
      default:
        return "Verbose";
    }
  }
}
