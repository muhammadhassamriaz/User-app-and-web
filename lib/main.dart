import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/provider/auth_provider.dart';
import 'package:flutter_grocery/provider/banner_provider.dart';
import 'package:flutter_grocery/provider/cart_provider.dart';
import 'package:flutter_grocery/provider/category_provider.dart';
import 'package:flutter_grocery/provider/chat_provider.dart';
import 'package:flutter_grocery/provider/coupon_provider.dart';
import 'package:flutter_grocery/provider/flash_deal_provider.dart';
import 'package:flutter_grocery/provider/language_provider.dart';
import 'package:flutter_grocery/provider/localization_provider.dart';
import 'package:flutter_grocery/provider/location_provider.dart';
import 'package:flutter_grocery/provider/news_letter_provider.dart';
import 'package:flutter_grocery/provider/notification_provider.dart';
import 'package:flutter_grocery/provider/onboarding_provider.dart';
import 'package:flutter_grocery/provider/order_provider.dart';
import 'package:flutter_grocery/provider/product_provider.dart';
import 'package:flutter_grocery/provider/profile_provider.dart';
import 'package:flutter_grocery/provider/search_provider.dart';
import 'package:flutter_grocery/provider/splash_provider.dart';
import 'package:flutter_grocery/provider/theme_provider.dart';
import 'package:flutter_grocery/provider/wallet_provider.dart';
import 'package:flutter_grocery/provider/wishlist_provider.dart';
import 'package:flutter_grocery/theme/dark_theme.dart';
import 'package:flutter_grocery/theme/light_theme.dart';
import 'package:flutter_grocery/utill/app_constants.dart';
import 'package:flutter_grocery/view/base/third_party_chat_widget.dart';
import 'package:flutter_grocery/view/screens/menu/menu_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart';
// import 'package:universal_ui/universal_ui.dart';
import 'package:url_strategy/url_strategy.dart';
import 'di_container.dart' as di;
import 'helper/notification_helper.dart';
import 'localization/app_localization.dart';
import 'view/base/cookies_view.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

AndroidNotificationChannel? channel;
Future<void> main() async {
  if (ResponsiveHelper.isMobilePhone()) {
    HttpOverrides.global = new MyHttpOverrides();
  }
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyAdS-mKt4XAd8KqJNRWX-OHKGh7lfl9uNI",
        authDomain: "gofresh-c944c.firebaseapp.com",
        projectId: "gofresh-c944c",
        storageBucket: "gofresh-c944c.appspot.com",
        messagingSenderId: "371788735721",
        appId: "1:371788735721:web:35fca5c2e1dd1140c27c78",
        measurementId: "G-9H7CRSMDP2",
      ),
    );

    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "YOUR_FACEBOOK_APP_ID",
      cookie: true,
      xfbml: true,
      version: "v13.0",
    );
  }
  await di.init();
  int? _orderID;
  try {
    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.high,
      );
    }
    final RemoteMessage? remoteMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (remoteMessage != null) {
      _orderID = remoteMessage.notification!.titleLocKey != null
          ? int.parse(remoteMessage.notification!.titleLocKey!)
          : null;
    }
    await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  } catch (e) {}

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => di.sl<ThemeProvider>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<LocalizationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SplashProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<OnBoardingProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CategoryProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProductProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<SearchProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ChatProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<AuthProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CartProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<CouponProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LocationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProfileProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<OrderProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<BannerProvider>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<NotificationProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<LanguageProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<NewsLetterProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<WishListProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<WalletProvider>()),
      ChangeNotifierProvider(create: (context) => di.sl<FlashDealProvider>()),
    ],
    child: MyApp(orderID: _orderID, isWeb: !kIsWeb),
  ));
}

class MyApp extends StatefulWidget {
  final int? orderID;
  final bool isWeb;
  MyApp({required this.orderID, required this.isWeb});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    RouteHelper.setupRouter();

    if (kIsWeb) {
      Provider.of<SplashProvider>(context, listen: false).initSharedData();
      Provider.of<CartProvider>(context, listen: false).getCartData();
      _route();
    }
  }

  void _route() {
    Provider.of<SplashProvider>(context, listen: false)
        .initConfig(context)
        .then((bool isSuccess) {
      if (isSuccess) {
        Timer(Duration(seconds: 1), () async {
          if (Provider.of<AuthProvider>(context, listen: false).isLoggedIn()) {
            Provider.of<AuthProvider>(context, listen: false).updateToken();
            // Navigator.of(context).pushReplacementNamed(RouteHelper.menu, arguments: MenuScreen());
            //Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen()));
          } else {
            // Navigator.of(context).pushReplacementNamed(RouteHelper.onBoarding, arguments: OnBoardingScreen());
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Locale> _locals = [];
    AppConstants.languages.forEach((language) {
      _locals.add(Locale(language.languageCode!, language.countryCode));
    });
    return Consumer<SplashProvider>(
      builder: (context, splashProvider, child) {
        return (kIsWeb && splashProvider.configModel == null)
            ? SizedBox()
            : MaterialApp(
                title: splashProvider.configModel != null
                    ? splashProvider.configModel!.ecommerceName ?? ''
                    : AppConstants.APP_NAME,
                // initialRoute: ResponsiveHelper.isMobilePhone()
                //     ? widget.orderID == null
                //         ? RouteHelper.splash
                //         : RouteHelper.getOrderDetailsRoute(widget.orderID)
                //     : Provider.of<SplashProvider>(context, listen: false)
                //             .configModel!
                //             .maintenanceMode!
                //         ? RouteHelper.getMaintenanceRoute()
                //         : RouteHelper.menu,
                // onGenerateRoute: RouteHelper.router.generator,
                debugShowCheckedModeBanner: false,
                navigatorKey: navigatorKey,
                theme: Provider.of<ThemeProvider>(context).darkTheme
                    ? dark
                    : light,
                locale: Provider.of<LocalizationProvider>(context).locale,
                localizationsDelegates: [
                  AppLocalization.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: _locals,
                scrollBehavior: MaterialScrollBehavior().copyWith(dragDevices: {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.unknown
                }),
                home: MenuScreen(),
                builder: (context, widget) => Material(
                    child: Stack(children: [
                  widget!,
                  if (ResponsiveHelper.isDesktop(context))
                    Positioned.fill(
                      child: Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 50, horizontal: 20),
                            child: ThirdPartyChatWidget(),
                          )),
                    ),
                  if (kIsWeb &&
                      splashProvider.configModel!.cookiesManagement != null &&
                      splashProvider.configModel!.cookiesManagement!.status! &&
                      !splashProvider.getAcceptCookiesStatus(splashProvider
                          .configModel!.cookiesManagement!.content) &&
                      splashProvider.cookiesShow)
                    Positioned.fill(
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: CookiesView())),
                ])),
              );
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class Get {
  static BuildContext? get context => navigatorKey.currentContext;
  static NavigatorState? get navigator => navigatorKey.currentState;
}
