import 'dart:math';

import 'package:alioli/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

import 'package:alioli/alioli.dart';
import 'package:alioli/screens/screens.dart';
import 'package:alioli/provider/provider.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/services/push_notification.dart';
import 'package:alioli/services/local_storage.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Log = logger(LoginScreen);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  bool _animationOn = false;
  String _loadingText = 'Iniciando sesión...';
  static String? token;

  // Variables animación
  double _containerHeight = 200;
  String _currentLogo = 'assets/logo2.svg';

  // Variables para crear un fondo estampado
  final int density = 4;
  final double width = 100.0;
  final double height = 100.0;
  List<Widget> svgWidgets = [];
  List<Offset> initialPositions = [];
  final List<String> svgAssets = [
    'assets/background/cheese0.svg',
    'assets/background/cherry0.svg',
    'assets/background/lemon0.svg',
    'assets/background/pear0.svg',
    'assets/background/pepper0.svg',
    'assets/background/tomato0.svg',
    'assets/background/onion0.svg',
    'assets/background/broccoli0.svg',
    'assets/background/pineapple0.svg',
    'assets/background/pepper1.svg',
    'assets/background/eggplant0.svg',
  ];

  // Iniciar sesión con correo
  void onFormLogin(
      String email,
      String password,
      context,
    ) async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    if ( _formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String emailLower = email.toLowerCase();

      loginProvider.loginUser(
          email: emailLower,
          password: password,
          onSuccess: () async {

            // Comprobar si el usuario ha verificado su correo
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null && (user.emailVerified || user.providerData.any((provider) => provider.providerId == 'google.com'))) {
              // Si el usuario ha verificado su correo
              Log.i('El usuario ha iniciado sesión correctamente');

              setState(() {
                _loadingText = 'Cargando datos del usuario...';
              });
              String imageUrl = await loginProvider.getImageUrl(email);
              String username = await loginProvider.getUsername(email);
              String? userId = await loginProvider.getUserId();
              String userRole = await loginProvider.getUserRole(email);
              await LocalStorage().saveUserData(_emailController.text, _passwordController.text);
              await LocalStorage().setIsLoggedIn(true);
              await LocalStorage().setUsername(username);
              await LocalStorage().saveUserRole(userRole);
              if ( imageUrl.isNotEmpty) {
                await LocalStorage().saveImageFromUrl(imageUrl);
              }

              if( userId != null) {
                await LocalStorage().saveUserId(userId);
              }

              setState(() {
                _loadingText = 'Descargando recetas favoritas...';
              });
              List<Recipe> likedRecipes = await loginProvider.getLikedRecipes();
              if( likedRecipes.isNotEmpty) {
                for (Recipe recipe in likedRecipes) {
                  await LocalStorage().addLikeRecipe(recipe);
                }
              }

              setState(() {
                _loadingText = 'Descargando recetas del usuario...';
              });
              List<Recipe> recipes = await loginProvider.getRecipes();
              if( recipes.isNotEmpty) {
                for (Recipe recipe in recipes) {
                  await LocalStorage().addPublishedRecipe(recipe);
                }
              }

              setState(() {
                _loadingText = 'Descargando listas de recetas...';
              });
              List<RecipeList> userRecipeLists = await loginProvider.getUserRecipeLists();
              for (RecipeList recipeList in userRecipeLists) {
                await LocalStorage().addRecipeList(recipeList);
              }

              // Cambiar estado de autenticación
              loginProvider.checkAuthState();

              setState(() {
                _isLoading = false;
              });

              // Animación y navegar a la pantalla principal
              expandAndNavigate();
            }else{
              // Si el usuario no ha verificado su correo
              setState(() {
                _isLoading = false;
              });
              Log.i('El usuario no ha verificado su correo');
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Verifica tu correo'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'Por favor, verifica tu correo electrónico para poder iniciar sesión',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Revise su carpeta de spam si no ha recibido el correo de verificación',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12
                          )
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Aceptar'),
                      )
                    ],
                  );
                }
              );
            }

          },
          onError: (String error) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email o contraseña incorrectos'),
                backgroundColor: Colors.red,
              )
            );
          }
      );

    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Iniciar sesión con Google
  void onGoogleSignIn(BuildContext context) async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
      _loadingText = 'Iniciando sesión con Google...';
    });

    await loginProvider.signInWithGoogle(
      onSuccess: () async {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          setState(() {
            _loadingText = 'Cargando datos del usuario...';
          });
          String email = user.email!;
          String imageUrl = await loginProvider.getImageUrl(email);
          String username = await loginProvider.getUsername(email);
          String? userId = user.uid;
          String userRole = await loginProvider.getUserRole(email);

          await LocalStorage().saveUserData(email, ''); // La contraseña no es necesaria para Google
          await LocalStorage().setIsLoggedIn(true);
          await LocalStorage().setUsername(username);
          await LocalStorage().saveUserRole(userRole);

          if (imageUrl.isNotEmpty) {
            await LocalStorage().saveImageFromUrl(imageUrl);
          }

          if (userId != null) {
            await LocalStorage().saveUserId(userId);
          }

          setState(() {
            _loadingText = 'Descargando recetas favoritas...';
          });
          List<Recipe> likedRecipes = await loginProvider.getLikedRecipes();
          if (likedRecipes.isNotEmpty) {
            for (Recipe recipe in likedRecipes) {
              await LocalStorage().addLikeRecipe(recipe);
            }
          }

          setState(() {
            _loadingText = 'Descargando recetas del usuario...';
          });
          List<Recipe> recipes = await loginProvider.getRecipes();
          if (recipes.isNotEmpty) {
            for (Recipe recipe in recipes) {
              await LocalStorage().addPublishedRecipe(recipe);
            }
          }

          setState(() {
            _loadingText = 'Descargando listas de recetas...';
          });
          List<RecipeList> userRecipeLists = await loginProvider.getUserRecipeLists();
          for (RecipeList recipeList in userRecipeLists) {
            await LocalStorage().addRecipeList(recipeList);
          }

          // Cambiar estado de autenticación
          loginProvider.checkAuthState();

          setState(() {
            _isLoading = false;
          });

          // Animación y navegar a la pantalla principal
          expandAndNavigate();
        }
      },
      onError: (String error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    token = PushNotificationService.token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      generateSvgWidgets(); // Llama a la generación inicial después de construir el widget
      setState(() {});
    });
  }
  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  void generateSvgWidgets() {
    final size = MediaQuery.of(context).size;
    final int rowCount = sqrt(density * density).floor();
    final double baseSpacing = min(size.width, size.height) / rowCount;

    svgWidgets.clear();
    final random = Random();

    List<Offset> positions = [];

    while (positions.length < density * density) {
      double dx = random.nextDouble() * size.width;
      double dy = random.nextDouble() * size.height;

      // Asegurarse de que no esté demasiado cerca de otras posiciones
      bool tooClose = positions.any((pos) => (pos.dx - dx).abs() < baseSpacing && (pos.dy - dy).abs() < baseSpacing);
      if (!tooClose) {
        positions.add(Offset(dx, dy));
      }
    }

    for (int i = 0; i < positions.length; i++) {
      final dx = positions[i].dx;
      final dy = positions[i].dy;
      final assetIndex = i % svgAssets.length;
      final asset = svgAssets[assetIndex];
      final rotation = (random.nextDouble() * 0.4) - 0.2; // Rotación aleatoria entre -0.2 y 0.2 radianes

      svgWidgets.add(Positioned(
        left: dx - width / 2, // Centra el SVG horizontalmente en dx
        top: dy - height / 2, // Centra el SVG verticalmente en dy
        child: Transform.rotate(
          angle: rotation,
          child: SvgPicture.asset(
            asset, width: width, height: height,
            color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Color(0xFF252424) : Color(0xFFF8F8F8),
          ),
        ),
      ));
    }
  }

  void expandAndNavigate() {
    // Inicia la animación del contenedor para que ocupe toda la pantalla
    setState(() {
      _animationOn = true;
      _containerHeight = MediaQuery.of(context).size.height;
    });

    // Espera a que la animación termine antes de cambiar la imagen
    Future.delayed(Duration(milliseconds: 500), () {
      // Cambia la imagen
      setState(() {
        _currentLogo = 'assets/logo.svg';
      });

      // Espera 1 segundos antes de navegar
      Future.delayed(Duration(seconds: 1), () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Alioli(isLogged: true)),
              (Route<dynamic> route) => false,
        );
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    double appWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          ...svgWidgets,
          Column(
            children: [
              // Header
              AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: _containerHeight,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50)
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        Text(
                          'Alioli',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                        SizedBox(height: 10),
                        SvgPicture.asset(
                            _currentLogo,
                            height: 50
                        ),
                      ],
                    ),
                  )
              ),
              const SizedBox(height: 20),
              if ( !_animationOn )
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          CustomTextField(
                            hintText: 'user@alioli.com',
                            labelText: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            suffixIcon: Icon(Icons.email_outlined),
                            validator: (value) {
                              if ( value!.isEmpty) {
                                return 'El email o usuario es necesario';
                              }
                              if (value.contains(' ')) {
                                return 'El email o usuario no pueden contener espacios';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'El email no es válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            hintText: '********',
                            labelText: 'Contraseña',
                            controller: _passwordController,
                            maxLines: 1,
                            keyboardType: TextInputType.visiblePassword,
                            suffixIcon: IconButton(
                                icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                onPressed: () {
                                  setState(() {
                                    _isObscure = !_isObscure;
                                  });
                                }
                            ),
                            obscureText: _isObscure,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'La contraseña es necesaria';
                              }
                              if (value.length < 8) {
                                return 'La contraseña debe tener al menos 8 caracteres';
                              }
                              if (value.length > 20) {
                                return 'La contraseña no puede tener más de 20 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                            ? Container(
                                width: appWidth/4,
                                child: LoadingIndicator(
                                  indicatorType: Indicator.ballClipRotateMultiple,
                                  colors: MediaQuery.of(context).platformBrightness==Brightness.dark ? const [Colors.white] : const [Colors.black],
                                ),
                              )
                            : Rounded3dButton('Iniciar Sesión', AppTheme.pantry,AppTheme.pantry_second, (){
                                onFormLogin(
                                    _emailController.text,
                                    _passwordController.text,
                                    context
                                );
                              }),
                          // Después del botón "Iniciar Sesión"
                          const SizedBox(height: 20),
                          _isLoading
                              ? SizedBox.shrink()
                              : Rounded3dButton(
                            'Accede con Google',
                            AppTheme.googleButtonColor,
                            AppTheme.googleButtonSecondColor,
                                () {
                              onGoogleSignIn(context);
                            },
                            icon: FontAwesomeIcons.google,
                          ),
                          const SizedBox(height: 20),
                          !_isLoading
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('¿No tienes cuenta?'),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                                  },
                                  child: const Text(
                                    'Regístrate',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                )
                              ],
                            )
                            : Text(_loadingText),

                        ]
                      ),
                    ),
                  )
                )
            ],
          ),
        ],
      )
    );
  }
}