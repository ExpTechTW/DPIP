import "package:dpip/global.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";

class SettingsLoginView extends StatefulWidget {
  const SettingsLoginView({super.key});

  @override
  State<SettingsLoginView> createState() => _SettingsLoginViewState();
}

class _SettingsLoginViewState extends State<SettingsLoginView> with WidgetsBindingObserver {
  bool monitorEnabled = Global.preference.getBool("monitor") ?? false;
  bool devEnabled = Global.preference.getBool("dev") ?? false;
  bool isLoggedIn = false; // 假设有一个方法来检查登录状态
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // 这里应该实现实际的登录逻辑
      setState(() {
        isLoggedIn = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.i18n.login_successful)),
      );
    }
  }

  void _logout() {
    // 这里应该实现实际的登出逻辑
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
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: context.i18n.email,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.i18n.please_enter_email;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: context.i18n.password,
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.i18n.please_enter_password;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
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