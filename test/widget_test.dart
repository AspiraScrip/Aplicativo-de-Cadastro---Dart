import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerenciador_pessoas/screens/login_screen.dart';

void main() {
  testWidgets('Tela de login apresenta os campos e botoes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Cadastrar novo usuário'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });
}
