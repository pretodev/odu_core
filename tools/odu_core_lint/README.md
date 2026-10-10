# Odu Core Lint

Regras de análise e ferramentas de IDE para projetos que usam Odu Core.
Adicione este pacote em `dev_dependencies` e mantenha `odu_core` em
`dependencies`. As regras estão em `lib/analysis_options.yaml`:

```yaml
include: package:odu_core_lint/analysis_options.yaml

plugins:
  odu_props_assist:
    path: caminho/para/odu_core_lint/plugin
```

O caminho do plugin é relativo ao `analysis_options.yaml` do consumidor.
O subpacote é resolvido separadamente pelo Analysis Server para evitar conflitos
entre versões do analyzer e os testes do Flutter. Adicionar a dependência não
ativa o plugin automaticamente. Este pacote ainda é local, sem publicação.

Veja as [ações e testes do plugin](plugin/README.md).
