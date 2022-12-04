import 'dart:async';
import 'dart:developer';

import 'package:faker/faker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sentry_demo/common_error_handler.dart';
import 'package:sentry_demo/firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/*


For Sentry.io credential:
Email: mijivo7789@cosaxu.com
Password: Dharam123

For Google Firebase credential:
Hint: DB1
Info: Contact Dharam Budh for access
*/

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await SentryFlutter.init(
        (options) {
          options.dsn =
              "https://d5016ce466484684b321ee536573146a@o1406093.ingest.sentry.io/6739529";
          options.tracesSampleRate = 1.0;
        },
        appRunner: () {
          FlutterError.onError = (FlutterErrorDetails details) async {
            await ErrorHandler().sendToCrashlyticsAndSentry(
              exception: details.exception,
              stackTrace: details.stack ?? StackTrace.current,
              hint: 'FlutterError.onError',
              onError: true,
              shouldSendReportToSentry: true,
              shouldSendReportToCrashlytics: true,
            );
          };
          runApp(
            const MyApp(),
          );
        },
      );
    },
    (exception, stackTrace) async {
      await ErrorHandler().sendToCrashlyticsAndSentry(
        exception: exception,
        stackTrace: stackTrace,
        hint: 'runZonedGuarded',
        onError: false,
        shouldSendReportToSentry: true,
        shouldSendReportToCrashlytics: true,
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          colorSchemeSeed: const Color(
            0xff6750a4,
          ),
        ),
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorSchemeSeed: const Color(
            0xff6750a4,
          ),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Faker _faker = Faker();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _formKey.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      floatingActionButton: speedDial(),
      body: form(),
    );
  }

  void successfulFunction() {
    log('came to testFunction'); // Successfully execute
    return;
  }

  void throwAKnownException() {
    throw Exception("Crash : ${DateTime.now()}"); // Exception caught
  }

  void throwAnUnknownError() {
    throw "Crash : ${DateTime.now()}"; // Error occurred
  }

  PreferredSizeWidget appBar() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        'Sentry & Crashlytics Demo',
      ),
      actions: [
        IconButton(
          onPressed: () {
            showBarModalBottomSheet(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              context: context,
              builder: (context) {
                return informationWidget();
              },
            );
          },
          icon: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.info_outline,
            ),
          ),
        ),
      ],
    );
  }

  Widget speedDial() {
    return SpeedDial(
      children: [
        SpeedDialChild(
          label: "Call A Successful Function",
          onTap: () {
            transporter(onTryFunction: successfulFunction);
          },
        ),
        SpeedDialChild(
          label: "Throw A Known Exception",
          onTap: () {
            transporter(onTryFunction: throwAKnownException);
          },
        ),
        SpeedDialChild(
          label: "Throw An Unknown Error",
          onTap: () {
            transporter(onTryFunction: throwAnUnknownError);
          },
        ),
      ],
      child: const Icon(
        Icons.add,
      ),
    );
  }

  Future<void> transporter({
    required Function onTryFunction,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ErrorHandler().handlerMethod(
      // if true, it will reflect to https://sentry.io/organizations/abc-ltd-m6/issues/
      shouldSendReportToSentry: true,

      // if true, it will reflect to https://console.firebase.google.com/u/0/project/crashlytics-demo-fd099/crashlytics/app/android:com.example.sentry_demo/issues/
      shouldSendReportToCrashlytics: true,

      // use suspicious method call here
      onTryFunction: () async {
        await onTryFunction();
      },

      // what if suspicious method successfully completed
      onExecutionSuccessfullyCompleted: () async {
        log("came to executionSuccessfullyCompleted");
        log('Executed successfully.');
        showSnackBar(text: 'Executed successfully.');
      },

      // what if they caught an known exception
      onExceptionCaught: (exception, stackTrace) async {
        log("came to onExceptionCaught");
        log('Crash report sent.');
        showSnackBar(text: 'Crash report sent.');
      },

      // what if they got an unknown error
      onErrorOccurred: (object, stackTrace) async {
        log("came to onErrorOccurred");
        log('Crash report sent.');
        showSnackBar(text: 'Crash report sent.');
      },

      // what if finally called
      onFinallyCalled: (errorStatus) async {
        log("came to onFinallyCalled");
        switch (errorStatus) {
          case ErrorStatus.success:
            log("Yay : $errorStatus");
            break;
          case ErrorStatus.failure:
            log("Oops : $errorStatus");
            break;
          case ErrorStatus.unknown:
            log("Oh : $errorStatus");
            break;
        }
      },
    );
  }

  Widget form() {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _textEditingController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter some feedback";
                  } else {
                    return null;
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Provide feedback",
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    SentryId sentryId = await Sentry.captureMessage(
                      "User Feedback : ${SentryId.newId()}",
                    );
                    SentryUserFeedback feedBack = SentryUserFeedback(
                      eventId: sentryId,
                      name: _faker.person.name(),
                      comments: _textEditingController.value.text,
                      email: _faker.internet.email(),
                    );
                    await Sentry.captureUserFeedback(
                      feedBack,
                    );
                    log('User Feedback sent.');
                    showSnackBar(text: 'User Feedback sent.');
                    _textEditingController.clear();
                  }
                },
                child: const Text(
                  "Submit feedback",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar({
    required String text,
  }) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
        ),
      ),
    );
  }

  Widget informationWidget() {
    return SingleChildScrollView(
      controller: ModalScrollController.of(context),
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "About this app",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "By using this application, you can unit test any function(). This application checks whether your provided function() is working or not. Based on your function's result, the app's handler function will give you some callbacks.",
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Required callbacks are below-mentioned:",
            ),
            const SizedBox(
              height: 5,
            ),
            const Text(
              "1. Provide the function() that you want to test.",
            ),
            const Text(
              "2. What action do you want to perform if the function() works and gets completed successfully?",
            ),
            const Text(
              "3. What action do you want to perform if the function() caught a known exception?",
            ),
            const Text(
              "4. What action do you want to perform if the function() grabs an unknown error?",
            ),
            const Text(
              "5. What action do you want to perform if the function() finally gets finished, no matter what results it gets?",
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Additional but required callbacks are below-mentioned:",
            ),
            const SizedBox(
              height: 5,
            ),
            const Text(
              "1. Should our app send the crash report to Sentry's server or not?",
            ),
            const Text(
              "If true, the crash report will be available on Sentry's server.",
            ),
            const Text(
              "2. Should our app send the crash report to Crashlytics's server or not?",
            ),
            const Text(
              "If true, the crash report will be available on Crashlytics's server.",
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Optional user feedback functionality:",
            ),
            const SizedBox(
              height: 5,
            ),
            const Text(
              "To reduce our server-side load, Sentry natively provides a user feedback dashboard, where you can get all the full-fledged information about the user's info., their remakes & their installed app information.",
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "For Sentry's & Crashlytics's dashboard access, Kindly contact me.",
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
