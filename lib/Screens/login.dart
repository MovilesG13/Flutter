import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50, // fondo azul
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de la app, billetera 
              const Icon(Icons.account_balance_wallet, size: 80, color: Colors.black),

              const SizedBox(height: 20),

              // Título. cambiar cuando se tenga nombre
              const Text(
                "FinanceApp",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // Subtítulo
              const Text(
                "Manage your finances smartly",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 32),

              // Campo correo o Login 
              TextField(
                decoration: InputDecoration(
                  labelText: "Username ",
                  hintText: "Username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Campo contraseña
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  // suffixIcon: Icon(Icons.visibility),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón de inicio de sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Aquí iría la lógica para iniciar sesión
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Log In"),
                ),
              ),

              const SizedBox(height: 16),

              // Recuperar contraseña
              TextButton(
                onPressed: () {},
                child: const Text("Forgot password?"),
              ),

              const SizedBox(height: 8),

             
            ],
          ),
        ),
      ),
    );
  }
}
