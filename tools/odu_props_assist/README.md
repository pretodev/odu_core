# Odu Props Assist

Plugin local do Analysis Server que adiciona a ação **Generate props** ao menu de
ações rápidas do editor (`Ctrl+.` / `Cmd+.`).

A ação aparece dentro de classes que estendem `Equatable`, `Entity` ou
`ViewModelState`. Campos estáticos e sintéticos são ignorados. Se a classe já
possuir um getter `props`, ele será atualizado.

O código gerado tem Dart 3.13.2 como versão mínima, reconhece todas as formas de
construtores primários e usa dot shorthand quando existe tipo contextual.

Após instalar ou alterar o plugin, reinicie o Dart Analysis Server pela paleta
de comandos do editor.
