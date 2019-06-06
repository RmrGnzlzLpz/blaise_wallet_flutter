import 'package:auto_size_text/auto_size_text.dart';
import 'package:blaise_wallet_flutter/appstate_container.dart';
import 'package:blaise_wallet_flutter/ui/util/app_icons.dart';
import 'package:blaise_wallet_flutter/ui/util/formatters.dart';
import 'package:blaise_wallet_flutter/ui/util/text_styles.dart';
import 'package:blaise_wallet_flutter/ui/widgets/app_text_field.dart';
import 'package:blaise_wallet_flutter/ui/widgets/buttons.dart';
import 'package:blaise_wallet_flutter/ui/widgets/tap_outside_unfocus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pascaldart/pascaldart.dart';

class IntroImportPrivateKeyPage extends StatefulWidget {
  @override
  _IntroImportPrivateKeyPageState createState() =>
      _IntroImportPrivateKeyPageState();
}

class _IntroImportPrivateKeyPageState extends State<IntroImportPrivateKeyPage> {
  FocusNode privateKeyFocusNode;
  TextEditingController privateKeyController;
  bool _showPrivateKeyError;
  bool _privateKeyValid;

  @override
  void initState() {
    super.initState();
    privateKeyFocusNode = FocusNode();
    privateKeyController = TextEditingController();
    _showPrivateKeyError = false;
    _privateKeyValid = false;
  }

  @override
  Widget build(BuildContext context) {
    // The main scaffold that holds everything
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: StateContainer.of(context).curTheme.backgroundPrimary,
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
              children: <Widget>[
                //A widget that holds welcome animation + paragraph
                Expanded(
                  child: TapOutsideUnfocus(
                    focusNodes: [privateKeyFocusNode],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // Container for the header
                        Container(
                          padding: EdgeInsetsDirectional.only(
                            top: (MediaQuery.of(context).padding.top) +
                                (24 - (MediaQuery.of(context).padding.top) / 2),
                          ),
                          decoration: BoxDecoration(
                            gradient: StateContainer.of(context)
                                .curTheme
                                .gradientPrimary,
                          ),
                          // Row for back button and the header
                          child: Row(
                            children: <Widget>[
                              // The header
                              Container(
                                width: MediaQuery.of(context).size.width - 60,
                                margin: EdgeInsetsDirectional.fromSTEB(
                                    30, 24, 30, 24),
                                child: AutoSizeText(
                                  "Import Private Key",
                                  style: AppStyles.header(context),
                                  maxLines: 1,
                                  stepGranularity: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        //Container for the paragraph
                        Container(
                          margin: EdgeInsetsDirectional.fromSTEB(30, 30, 30, 0),
                          alignment: Alignment(-1, 0),
                          child: AutoSizeText(
                            "Enter your private key below.",
                            maxLines: 2,
                            stepGranularity: 0.1,
                            style: AppStyles.paragraph(context),
                          ),
                        ),
                        // Container for the text field
                        Container(
                          margin: EdgeInsetsDirectional.fromSTEB(30, 24, 30, 0),
                          child: AppTextField(
                            label: "Private Key",
                            style: _privateKeyValid ? AppStyles.privateKeyPrimary(context) : AppStyles.privateKeyTextDark(context),
                            focusNode: privateKeyFocusNode,
                            controller: privateKeyController,
                            firstButton: TextFieldButton(
                              icon: AppIcons.paste,
                              onPressed: () {
                                Clipboard.getData("text/plain").then((cdata) {
                                  if (privateKeyIsValid(cdata.text) || privateKeyIsEncrypted(cdata.text)) {
                                    privateKeyController.text = cdata.text;
                                    onKeyTextChanged(privateKeyController.text);
                                  }
                                });
                              },
                            ),
                            secondButton: TextFieldButton(
                              icon: AppIcons.scan,
                              onPressed: () {
                                // Scan private key TODO
                              },
                            ),
                            inputFormatters: [
                              WhitelistingTextInputFormatter(RegExp("[a-fA-F0-9]")), // Hex characters
                              UpperCaseTextFormatter()
                            ],
                            textCapitalization: TextCapitalization.characters,
                            onChanged: onKeyTextChanged,
                          )
                        ),
                        Container(
                          child: Text(
                            _showPrivateKeyError ? "Private key is invalid" : "",
                            style: AppStyles.paragraphPrimary(context),
                            textAlign: TextAlign.center,
                          ),
                        )
                      ],
                    )
                  ),
                ),

                //"Import" and "Go Back" buttons
                // "Import" button
                    Row(
                      children: <Widget>[
                        AppButton(
                          type: AppButtonType.Primary,
                          text: "Import",
                          buttonTop: true,
                          onPressed: () {
                            validateAndSubmit();
                          },
                        ),
                      ],
                    ),
                    // "Go Back" button
                    Row(
                      children: <Widget>[
                        AppButton(
                          type: AppButtonType.PrimaryOutline,
                          text: "Go Back",
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
              ],
            ),
      ),
    );
  }

  bool privateKeyIsValid(String pkText) {
    try {
      PrivateKeyCoder().decodeFromBytes(PDUtil.hexToBytes(pkText));
      return true;
    } catch (e) {
      return false;
    }
  }

  bool privateKeyIsEncrypted(String pkText, { bool lengthCheck = true }) {
    int minLength = lengthCheck ? 100 : 8;
    if (pkText == null || pkText.length < minLength) {
      return false;
    }
    try {
      String salted = PDUtil.bytesToUtf8String(PDUtil.hexToBytes(pkText.substring(0, 8)));
      if (salted == "Salted__") {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void onKeyTextChanged(String newText) {
    if (privateKeyIsValid(newText)) {
      privateKeyFocusNode.unfocus();
      setState(() {
        _privateKeyValid = true;
        _showPrivateKeyError = false;
      });
    } else {
      setState(() {
        _privateKeyValid = false;
        _showPrivateKeyError = false;
      });
    }
  }

  void validateAndSubmit() {
    if (privateKeyIsValid(privateKeyController.text)) {
      Navigator.of(context).pushNamed('/overview');
    } else if (privateKeyIsEncrypted(privateKeyController.text)) {
      Navigator.of(context).pushNamed(
        '/intro_decrypt_and_import_private_key',
        arguments: privateKeyController.text);
    } else {
      setState(() {
        _showPrivateKeyError = true;
      });
    }
  }
}
