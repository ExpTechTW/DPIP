import "package:dpip/api/exptech.dart";
import "package:dpip/global.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/util/log.dart";
import "package:flutter/material.dart";

class SettingsLoginView extends StatefulWidget {
  const SettingsLoginView({super.key});

  @override
  State<SettingsLoginView> createState() => _SettingsLoginViewState();
}

class _SettingsLoginViewState extends State<SettingsLoginView> with WidgetsBindingObserver {
  bool monitorEnabled = Global.preference.getBool("monitor") ?? false;
  bool devEnabled = Global.preference.getBool("dev") ?? false;
  bool isLoggedIn = Global.preference.getBool("isLoggedIn") ?? false;
  String token = Global.preference.getString("token") ?? "";
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        String result = await ExpTech().login(_usernameController.text, _emailController.text, _passwordController.text);
        TalkerManager.instance.debug("登入: $result");
        Global.preference.setString("token",result);
        Global.preference.setBool("isLoggedIn",true);
        setState(() {
          token = result;
          isLoggedIn = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.i18n.login_successful)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
        Global.preference.setBool("isLoggedIn",false);
        setState(() {
          isLoggedIn = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ExpTech().logout(token);
    Global.preference.remove("token");
    Global.preference.setBool("isLoggedIn",false);
    setState(() {
      isLoggedIn = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.i18n.logout_successful)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: [
          if (!isLoggedIn) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: context.i18n.username,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: context.i18n.email,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.i18n.please_enter_email;
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return context.i18n.please_enter_valid_email;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: context.i18n.password,
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.i18n.please_enter_password;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _login,
                      child: Text(context.i18n.login),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListTile(
              // title: Text(context.i18n.logged_in_as(Global.username)), // 假设 Global.username 存储了登录用户的名字
              title: Text(context.i18n.logout),
              trailing: ElevatedButton(
                onPressed: _logout,
                child: Text(context.i18n.logout),
              ),
            ),
          ],
        ],
      ),
    );
  }
}