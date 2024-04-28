import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:dpip/constants.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  int? eewIntensityThreshold = Global.preference.getInt('notification:eew_intensity');
  int? intensityThreshold = Global.preference.getInt('notification:intensity_intensity');
  int? reportIntensityThreshold = Global.preference.getInt('notification:report_intensity');

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('通知'),
        ),
        child: CupertinoScrollbar(
          child: ListView(
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.bell),
                title: const Text('系統通知設定'),
                onTap: () {
                  AppSettings.openAppSettings(type: AppSettingsType.notification);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text(
                  "緊急地震速報",
                  style: TextStyle(color: context.colors.outline),
                ),
              ),
              CupertinoListTile(
                title: const Text("接收緊急地震速報通知"),
                subtitle: const Text("選擇是否要接收緊急地震速報通知"),
                trailing: CupertinoSwitch(
                  value: Global.preference.getBool("notification:eew") ?? true,
                  onChanged: (value) {
                    setState(() {
                      Global.preference.setBool("notification:eew", value);
                    });
                  },
                ),
              ),
              CupertinoListTile(
                title: const Text("所在地震度門檻"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      eewIntensityThreshold != null ? IntensityList[eewIntensityThreshold! - 1].name : '無所在地震度門檻',
                      style: TextStyle(
                        color: Global.preference.getBool("notification:eew") ?? true
                            ? context.colors.intensity(eewIntensityThreshold ?? 0)
                            : context.colors.intensity(eewIntensityThreshold ?? 0).withOpacity(0.4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text("當緊急地震速報預估所在地震度達設定門檻時才會收到通知"),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text("所在地震度門檻"),
                      content: SizedBox(
                        width: double.minPositive,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: IntensityList.length,
                          itemBuilder: (context, index) => RadioListTile(
                            value: IntensityList[index].value,
                            groupValue: eewIntensityThreshold,
                            title: Text(IntensityList[index].name),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  eewIntensityThreshold = value;
                                  Global.preference.setInt('notification:eew_intensity', value);
                                });
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text("清除門檻"),
                          onPressed: () {
                            setState(() {
                              eewIntensityThreshold = null;
                              Global.preference.remove('notification:eew_intensity');
                            });
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoDialogAction(
                          child: const Text("取消"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text(
                  "強震監視器",
                  style: TextStyle(color: context.colors.outline),
                ),
              ),
              CupertinoListTile(
                title: const Text("接收強震監視器通知"),
                subtitle: const Text("選擇是否要接收強震監視器通知"),
                trailing: CupertinoSwitch(
                  value: Global.preference.getBool("notification:monitor") ?? true,
                  onChanged: (value) {
                    setState(() {
                      Global.preference.setBool("notification:monitor", value);
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text(
                  "震度速報",
                  style: TextStyle(color: context.colors.outline),
                ),
              ),
              CupertinoListTile(
                title: const Text("接收震度速報通知"),
                subtitle: const Text("選擇是否要接收震度速報通知"),
                trailing: CupertinoSwitch(
                  value: Global.preference.getBool("notification:intensity") ?? true,
                  onChanged: (value) {
                    setState(() {
                      Global.preference.setBool("notification:intensity", value);
                    });
                  },
                ),
              ),
              CupertinoListTile(
                title: const Text("所在地震度門檻"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      intensityThreshold != null ? IntensityList[intensityThreshold! - 1].name : '無所在地震度門檻',
                      style: TextStyle(
                        color: Global.preference.getBool("notification:intensity") ?? true
                            ? context.colors.intensity(intensityThreshold ?? 0)
                            : context.colors.intensity(intensityThreshold ?? 0).withOpacity(0.4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text("當震度速報所在地震度達設定門檻時才會收到通知"),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text("所在地震度門檻"),
                      content: SizedBox(
                        width: double.minPositive,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: IntensityList.length,
                          itemBuilder: (context, index) => RadioListTile(
                            value: IntensityList[index].value,
                            groupValue: intensityThreshold,
                            title: Text(IntensityList[index].name),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  intensityThreshold = value;
                                  Global.preference.setInt('notification:intensity_intensity', value);
                                });
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text("清除門檻"),
                          onPressed: () {
                            setState(() {
                              intensityThreshold = null;
                              Global.preference.remove('notification:intensity_intensity');
                            });
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoDialogAction(
                          child: const Text("取消"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                child: Text(
                  "地震報告",
                  style: TextStyle(color: context.colors.outline),
                ),
              ),
              CupertinoListTile(
                title: const Text("接收地震報告通知"),
                subtitle: const Text("選擇是否要接收地震報告通知"),
                trailing: CupertinoSwitch(
                  value: Global.preference.getBool("notification:report") ?? true,
                  onChanged: (value) {
                    setState(() {
                      Global.preference.setBool("notification:report", value);
                    });
                  },
                ),
              ),
              CupertinoListTile(
                title: const Text("編號地震報告"),
                subtitle: const Text("選擇是否只接收有編號地震報告通知"),
                trailing: CupertinoSwitch(
                  value: Global.preference.getBool("notification:report_numbered") ?? true,
                  onChanged: Global.preference.getBool("notification:report") ?? true
                      ? (value) {
                          setState(() {
                            Global.preference.setBool("notification:report_numbered", value);
                          });
                        }
                      : null,
                ),
              ),
              CupertinoListTile(
                title: const Text("所在地震度門檻"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      reportIntensityThreshold != null ? IntensityList[reportIntensityThreshold! - 1].name : '無所在地震度門檻',
                      style: TextStyle(
                        color: Global.preference.getBool("notification:report") ?? true
                            ? context.colors.intensity(reportIntensityThreshold ?? 0)
                            : context.colors.intensity(reportIntensityThreshold ?? 0).withOpacity(0.4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text("當地震報告所在地震度達設定門檻時才會收到通知"),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text("所在地震度門檻"),
                      content: SizedBox(
                        width: double.minPositive,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: IntensityList.length,
                          itemBuilder: (context, index) => RadioListTile(
                            value: IntensityList[index].value,
                            groupValue: reportIntensityThreshold,
                            title: Text(IntensityList[index].name),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  reportIntensityThreshold = value;
                                  Global.preference.setInt('notification:report_intensity', value);
                                });
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text("清除門檻"),
                          onPressed: () {
                            setState(() {
                              reportIntensityThreshold = null;
                              Global.preference.remove('notification:report_intensity');
                            });
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoDialogAction(
                          child: const Text("取消"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("通知"),
        ),
        body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_rounded),
              title: const Text('系統通知設定'),
              onTap: () {
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
              child: Text(
                "緊急地震速報",
                style: TextStyle(color: context.colors.outline),
              ),
            ),
            ListTile(
              title: const Text("接收緊急地震速報通知"),
              subtitle: const Text("選擇是否要接收緊急地震速報通知"),
              trailing: Switch(
                value: Global.preference.getBool("notification:eew") ?? true,
                onChanged: (value) {
                  setState(() {
                    Global.preference.setBool("notification:eew", value);
                  });
                },
              ),
            ),
            ListTile(
              title: const Text("所在地震度門檻"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    eewIntensityThreshold != null ? IntensityList[eewIntensityThreshold! - 1].name : '無所在地震度門檻',
                    style: TextStyle(
                      color: Global.preference.getBool("notification:eew") ?? true
                          ? context.colors.intensity(eewIntensityThreshold ?? 0)
                          : context.colors.intensity(eewIntensityThreshold ?? 0).withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text("當緊急地震速報預估所在地震度達設定門檻時才會收到通知"),
                ],
              ),
              enabled: Global.preference.getBool("notification:eew") ?? true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("所在地震度門檻"),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
                    content: SizedBox(
                      width: double.minPositive,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: IntensityList.length,
                        itemBuilder: (context, index) => RadioListTile(
                          value: IntensityList[index].value,
                          groupValue: eewIntensityThreshold,
                          title: Text(IntensityList[index].name),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                eewIntensityThreshold = value;
                                Global.preference.setInt('notification:eew_intensity', value);
                              });
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text("清除門檻"),
                        onPressed: () {
                          setState(() {
                            eewIntensityThreshold = null;
                            Global.preference.remove('notification:eew_intensity');
                          });
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: const Text("取消"),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
              child: Text(
                "強震監視器",
                style: TextStyle(color: context.colors.outline),
              ),
            ),
            ListTile(
              title: const Text("接收強震監視器通知"),
              subtitle: const Text("選擇是否要接收強震監視器通知"),
              trailing: Switch(
                value: Global.preference.getBool("notification:monitor") ?? true,
                onChanged: (value) {
                  setState(() {
                    Global.preference.setBool("notification:monitor", value);
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
              child: Text(
                "震度速報",
                style: TextStyle(color: context.colors.outline),
              ),
            ),
            ListTile(
              title: const Text("接收震度速報通知"),
              subtitle: const Text("選擇是否要接收震度速報通知"),
              trailing: Switch(
                value: Global.preference.getBool("notification:intensity") ?? true,
                onChanged: (value) {
                  setState(() {
                    Global.preference.setBool("notification:intensity", value);
                  });
                },
              ),
            ),
            ListTile(
              title: const Text("所在地震度門檻"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    intensityThreshold != null ? IntensityList[intensityThreshold! - 1].name : '無所在地震度門檻',
                    style: TextStyle(
                      color: Global.preference.getBool("notification:intensity") ?? true
                          ? context.colors.intensity(intensityThreshold ?? 0)
                          : context.colors.intensity(intensityThreshold ?? 0).withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text("當震度速報所在地震度達設定門檻時才會收到通知"),
                ],
              ),
              enabled: Global.preference.getBool("notification:intensity") ?? true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("所在地震度門檻"),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
                    content: SizedBox(
                      width: double.minPositive,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: IntensityList.length,
                        itemBuilder: (context, index) => RadioListTile(
                          value: IntensityList[index].value,
                          groupValue: intensityThreshold,
                          title: Text(IntensityList[index].name),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                intensityThreshold = value;
                                Global.preference.setInt('notification:intensity_intensity', value);
                              });
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text("清除門檻"),
                        onPressed: () {
                          setState(() {
                            intensityThreshold = null;
                            Global.preference.remove('notification:intensity_intensity');
                          });
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: const Text("取消"),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
              child: Text(
                "地震報告",
                style: TextStyle(color: context.colors.outline),
              ),
            ),
            ListTile(
              title: const Text("接收地震報告通知"),
              subtitle: const Text("選擇是否要接收地震報告通知"),
              trailing: Switch(
                value: Global.preference.getBool("notification:report") ?? true,
                onChanged: (value) {
                  setState(() {
                    Global.preference.setBool("notification:report", value);
                  });
                },
              ),
            ),
            ListTile(
              title: const Text("編號地震報告"),
              subtitle: const Text("選擇是否只接收有編號地震報告通知"),
              trailing: Switch(
                value: Global.preference.getBool("notification:report_numbered") ?? true,
                onChanged: Global.preference.getBool("notification:report") ?? true
                    ? (value) {
                        setState(() {
                          Global.preference.setBool("notification:report_numbered", value);
                        });
                      }
                    : null,
              ),
              enabled: Global.preference.getBool("notification:report") ?? true,
            ),
            ListTile(
              title: const Text("所在地震度門檻"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reportIntensityThreshold != null ? IntensityList[reportIntensityThreshold! - 1].name : '無所在地震度門檻',
                    style: TextStyle(
                      color: Global.preference.getBool("notification:report") ?? true
                          ? context.colors.intensity(reportIntensityThreshold ?? 0)
                          : context.colors.intensity(reportIntensityThreshold ?? 0).withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text("當地震報告所在地震度達設定門檻時才會收到通知"),
                ],
              ),
              enabled: Global.preference.getBool("notification:report") ?? true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("所在地震度門檻"),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
                    content: SizedBox(
                      width: double.minPositive,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: IntensityList.length,
                        itemBuilder: (context, index) => RadioListTile(
                          value: IntensityList[index].value,
                          groupValue: reportIntensityThreshold,
                          title: Text(IntensityList[index].name),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                reportIntensityThreshold = value;
                                Global.preference.setInt('notification:report_intensity', value);
                              });
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text("清除門檻"),
                        onPressed: () {
                          setState(() {
                            reportIntensityThreshold = null;
                            Global.preference.remove('notification:report_intensity');
                          });
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: const Text("取消"),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }
}
