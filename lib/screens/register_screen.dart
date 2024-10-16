  import 'dart:io';

  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:loading_indicator/loading_indicator.dart';
  import 'package:provider/provider.dart';
  import 'package:password_strength_checker/password_strength_checker.dart';


  import 'package:alioli/components/components.dart';
  import 'package:alioli/components/utils.dart';
  import 'package:alioli/provider/provider.dart';
  import 'package:alioli/provider/register_provider.dart';
  import 'package:alioli/services/push_notification.dart';

  class RegisterScreen extends StatefulWidget {
    const RegisterScreen({Key? key}) : super(key: key);

    @override
    State<RegisterScreen> createState() => _RegisterScreenState();
  }


  class _RegisterScreenState extends State<RegisterScreen> {
    final Log = logger(RegisterScreen);
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _repeatPasswordController = TextEditingController();
    final ValueNotifier<CustomPasswordStrength?> passNotifier = ValueNotifier<CustomPasswordStrength?>(null);

    bool _isObscure = true;
    bool _isLoading = false;
    File? image;
    static String? token;
    String _loadingText = 'Registrando usuario...';

    void showSnackBar(BuildContext context, String text, Color color){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: color,
          content: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
            )
          ),
        ),
      );
    }

    @override
    void initState() {
      super.initState();
      token = PushNotificationService.token;
    }

    @override
    void dispose() {
      super.dispose();
      _usernameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
    }


    // Registrar al usuario
    void submitRegister() async {
      Log.i('Botón de registro pulsado');
      final registerProvider = Provider.of<RegisterProvider>(context, listen: false);
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });

        if(await containsOffensiveContent(_usernameController.text)){
          mostrarMensaje('El nombre de usuario contiene palabras ofensivas');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _loadingText = 'Verficando disponibilidad...';
        });

        // Verificar si el nombre de usuario ya existe
        final bool existUsername = await registerProvider.checkUserExists(_usernameController.text);
        if (existUsername) {
          setState(() {
            _isLoading = false;
          });
          Log.i('Registrar usuario: El usuario ya está en uso');
          showSnackBar(context, 'El usuario ya está en uso', Colors.red);
          return;
        }

        // Verificamos si el email ya existe
        final bool existEmail = await registerProvider.checkEmailExists(_emailController.text);
        if(existEmail) {
          setState(() {
            _isLoading = false;
          });
          Log.i('Registrar usuario: El email ya está en uso');
          showSnackBar(context, 'El email ya está en uso', Colors.red);
          return;
        }

        setState(() {
          _loadingText = 'Haciendo alioli...';
        });

        // Registrar al usuario
        try {
          await registerProvider.registerUser(
            username: _usernameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            rol: UserRole.USER,
            token: token!,
            createdAt: DateTime.now().toString(),
            image: image,
            onError: (String error) {
              showSnackBar(context, error, Colors.red);
            },
          );

          setState(() {
            _isLoading = false;
          });

          // Enviar correo de verificación
          await FirebaseAuth.instance.currentUser!.sendEmailVerification();
          showSnackBar(context, 'Revise su correo para verificar su cuenta', AppTheme.basket);
          Navigator.pop(context);
        } on FirebaseAuthException catch (e) {
          showSnackBar(context, e.message!, Colors.red);
        } catch (e) {
          showSnackBar(context, e.toString(), Colors.red);
        }

      }else{
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Seleccionar una imagen
    void selectedImage() async {
      image = await pickImageCompress(20);
      setState(() {
        image = image;
      });
    }

    @override
    Widget build(BuildContext context) {
      double appWidth = MediaQuery.of(context).size.width;

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: const Text(
            'Registro',
            style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  InkWell(
                    onTap: () {
                      selectedImage();
                    },
                    child: image == null
                        ? const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        )
                        : CircleAvatar(
                      radius: 50,
                      backgroundImage: FileImage(image!),
                    ),
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    hintText: 'user123',
                    labelText: 'Usuario',
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    suffixIcon: Icon(Icons.person_outline),
                    validator: (value) {
                      if ( value!.isEmpty) {
                        return 'El usuario es necesario';
                      }
                      if (value.contains(' ')) {
                        return 'El usuario no pueden contener espacios';
                      }
                      if (value.length < 4) {
                        return 'El usuario debe tener al menos 4 caracteres';
                      }
                      if (value.length > 20) {
                        return 'El usuario no puede tener más de 20 caracteres';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(value)) {
                        return 'El usuario no puede contener caracteres especiales';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    hintText: 'user@alioli.com',
                    labelText: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    suffixIcon: Icon(Icons.email_outlined),
                    validator: (value) {
                      if ( value!.isEmpty) {
                        return 'El email es necesario';
                      }
                      if (value.contains(' ')) {
                        return 'El email no puede contener espacios';
                      }
                      if ( !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Introduce un email válido';
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
                    onChanged: (value) {
                      passNotifier.value = CustomPasswordStrength.calculate(text: value);
                    },
                  ),
                  const SizedBox(height: 20),
                  PasswordStrengthChecker<CustomPasswordStrength>(
                    strength: passNotifier,
                    configuration: PasswordStrengthCheckerConfiguration(
                      inactiveBorderColor: Colors.grey,
                      borderWidth: 1,
                      animationDuration: const Duration(milliseconds: 300),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    hintText: '********',
                    labelText: 'Repite la contraseña',
                    controller: _repeatPasswordController,
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
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? Container(
                          width: appWidth/4,
                          child: LoadingIndicator(
                            indicatorType: Indicator.ballClipRotateMultiple,
                            colors: MediaQuery.of(context).platformBrightness==Brightness.dark ? const [Colors.white] : const [Colors.black],
                          ),
                        )
                      : Rounded3dButton('Registrarse',AppTheme.pantry,AppTheme.pantry_second,submitRegister),
                  const SizedBox(height: 20),
                  !_isLoading
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿Ya tienes cuenta?'),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        )
                      ],
                    )
                  : Text(_loadingText),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }



  enum CustomPasswordStrength implements PasswordStrengthItem {
    yaExpuesto,
    debil,
    medio,
    fuerte,
    seguro;

    @override
    Color get statusColor {
      switch (this) {
        case CustomPasswordStrength.yaExpuesto:
          return const Color.fromARGB(255, 158, 15, 5);
        case CustomPasswordStrength.debil:
          return Colors.red;
        case CustomPasswordStrength.medio:
          return Colors.orange;
        case CustomPasswordStrength.fuerte:
          return Colors.green;
        case CustomPasswordStrength.seguro:
          return const Color(0xFF0B6C0E);
        default:
          return Colors.red;
      }
    }

    @override
    double get widthPerc {
      switch (this) {
        case CustomPasswordStrength.yaExpuesto:
          return 0.075;
        case CustomPasswordStrength.debil:
          return 0.15;
        case CustomPasswordStrength.medio:
          return 0.4;
        case CustomPasswordStrength.fuerte:
          return 0.75;
        case CustomPasswordStrength.seguro:
          return 1.0;
      }
    }

    @override
    Widget? get statusWidget {
      switch (this) {
        case CustomPasswordStrength.yaExpuesto:
          return Row(
            children: [const Text('Muy vulnerable'), const SizedBox(width: 5), Icon(Icons.error, color: statusColor)],
          );
        case CustomPasswordStrength.debil:
          return const Text('Débil');
        case CustomPasswordStrength.medio:
          return const Text('Medio');
        case CustomPasswordStrength.fuerte:
          return const Text('Fuerte');
        case CustomPasswordStrength.seguro:
          return Row(
            children: [const Text('Seguro'), const SizedBox(width: 5), Icon(Icons.check_circle, color: statusColor)],
          );
        default:
          return null;
      }
    }

    static CustomPasswordStrength? calculate({required String text}) {
      if (text.isEmpty) {
        return null;
      }

      if (commonDictionary[text] == true) {
        return CustomPasswordStrength.yaExpuesto;
      }

      if (text.length < 8) {
        return CustomPasswordStrength.debil;
      }

      var counter = 0;
      if (text.contains(RegExp(r'[a-z]'))) counter++;
      if (text.contains(RegExp(r'[A-Z]'))) counter++;
      if (text.contains(RegExp(r'[0-9]'))) counter++;
      if (text.contains(RegExp(r'[!@#\$%&*()?£\-_=]'))) counter++;

      switch (counter) {
        case 1:
          return CustomPasswordStrength.debil;
        case 2:
          return CustomPasswordStrength.medio;
        case 3:
          return CustomPasswordStrength.fuerte;
        case 4:
          return CustomPasswordStrength.seguro;
        default:
          return CustomPasswordStrength.debil;
      }
    }

    static String get instructions {
      return 'Introduce una contraseña que contenga:\n\n'
          '• Al menos 8 caracteres\n'
          '• Al menos 1 letra minúscula\n'
          '• Al menos 1 letra mayúscula\n'
          '• Al menos 1 dígito\n'
          '• Al menos 1 carácter especial';
    }
  }