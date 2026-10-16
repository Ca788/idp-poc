# IdP (estudo / POC)

Identity Provider SAML 2.0 em Ruby on Rails. **Não é produto, não é IdP de produção.** É um estudo para entender o papel de um autenticador central: um login no IdP, N aplicações plugadas como Service Provider.

Use para aprender o fluxo, plugar SPs de teste e ler o código. Não use para autenticar sistemas reais, dados de clientes ou ambiente exposto na internet.

## O que este estudo cobre

- Login por organização + e-mail + senha (bcrypt)
- Sessão no IdP (`IdentitySession`, 12h, cookie HttpOnly)
- Cadastro de `ClientApplication` (SAML) por org
- SSO SAML 2.0 **iniciado pelo SP** (Web Browser SSO)
- Assertion **assinada (SHA-256) e cifrada** (AES-256-CBC + RSA-OAEP) com o certificado do SP
- Metadata SAML assinado em `/saml/metadata`
- Isolamento multi-tenant: usuário e cliente só resolvem dentro da mesma org

Duas apps da **mesma organização** compartilham o login: a primeira pede senha; a segunda, com a sessão do IdP viva, só recebe outra assertion. Cada app continua com a sessão **local** dela. O IdP não entra no produto.

## O que não está no escopo

- OIDC (o protocolo existe no cadastro; o issuer ainda não emite)
- MFA, SSO iniciado pelo IdP, logout SAML (SLO)
- UI de admin, convite de usuário, gestão de chaves em HSM
- Deploy pronto (Kamal está no scaffold do Rails 8, sem configuração deste estudo)

Em produção o código exige `https` em `IDP_BASE_URL` e chave do IdP via ENV. Isso não transforma o POC em IdP operacional.

## Stack

Rails 8.1 (API + views mínimas de login/ACS), Ruby 3.3, PostgreSQL 16 (porta **5434** no host), gem `saml_idp` 1.0.0.

Camadas do estudo, de propósito simples:

`controller → use case → model` — XML SAML fica em `app/infrastructure/sso`.

## Subir local

Postgres em `localhost:5434`, usuário/senha `postgres` (ver `.env.example`).

```bash
cp .env.example .env
bin/setup --skip-server
bin/rails db:seed
bin/dev
```

Certificado de desenvolvimento é gerado em `tmp/certs/` se não houver `IDP_X509_CERTIFICATE`.

Seed:

| Campo | Valor |
| --- | --- |
| Organização (slug) | `acme` |
| E-mail | `admin@acme.test` |
| Senha | `changeme123` |

Login no browser: http://localhost:3000/login

## Endpoints

| Método | Caminho | Função |
| --- | --- | --- |
| GET/POST | `/login` | Login HTML (fluxo SSO no browser) |
| POST | `/api/v1/login` | Login JSON (`X-Organization-Id`) |
| GET | `/saml/metadata` | Metadata do IdP (assinado, sem SLO) |
| GET/POST | `/saml/auth` | SSO SAML (AuthnRequest → ACS da app) |
| GET/POST | `/api/v1/client_applications` | Listar/cadastrar SPs da org (`fields`, paginação) |

Listagens da API aceitam `page`, `per_page` e `fields`. Todo acesso a dado de negócio é no escopo da organização.

## Plugar duas aplicações

1. Cada app é um SAML SP. No IdP, cadastre um `ClientApplication` por app, na **mesma org**:

```bash
curl -X POST http://localhost:3000/api/v1/client_applications \
  -H "X-Organization-Id: <uuid da org acme>" \
  -d "name=App A" \
  -d "protocol=saml" \
  -d "entity_id=https://app-a.test/metadata" \
  -d "acs_url=https://app-a.test/sso/callback" \
  -d "sp_certificate=<PEM do certificado público do SP>"
```

2. No SP: Entity ID do IdP = `IDP_BASE_URL/saml/metadata`, SSO URL = `IDP_BASE_URL/saml/auth`, ACS = a URL cadastrada **exata**.
3. A app redireciona o browser para `/saml/auth?SAMLRequest=...`. Sem sessão, o IdP manda para `/login`. Depois do login, o browser faz POST automático no ACS com `SAMLResponse` (cifrado) e `RelayState`.
4. Repita na segunda app. Com o cookie do IdP ainda válido, não há senha de novo.

O SP precisa validar assinatura, `InResponseTo`, Audience (`entity_id`), Destination/Recipient e janela de tempo. O IdP não substitui essa parte.

## Variáveis

| Variável | Uso |
| --- | --- |
| `IDP_BASE_URL` | Base do metadata e das URLs SSO. Dev: `http://localhost:3000`. Produção: **obrigatório `https://`** |
| `IDP_X509_CERTIFICATE` / `IDP_PRIVATE_KEY` | Chave de assinatura do IdP. Obrigatórias em produção; em dev geradas em `tmp/certs/` |
| `DB_HOST` / `DB_PORT` / `POSTGRES_*` | Postgres (default porta 5434) |

## Testes

```bash
bundle exec rspec
```

Cobre cifra da assertion, `InResponseTo`, Destination, replay de AuthnRequest, isolamento entre orgs, rotação de sessão no login e rate limit no `/api/v1/login`.

## Decisões de estudo (e limites)

- Senha só no IdP. Apps recebem prova criptográfica, não a senha.
- ACS é match **exato** (org + `entity_id` + `acs_url`). URL “parecida” não passa.
- NameID é e-mail; `sub` (id do usuário) vai como atributo cifrado.
- Sem logout único: sair de uma app não derruba a outra nem a sessão do IdP.
- Rate limit de login é in-memory (OK para o POC; em multi-processo precisaria de cache compartilhado).

Se for evoluir este código para algo além de estudo, trate como recomeço com ameaça real, chave gerenciada, TLS ponta a ponta e revisão de um IdP de verdade — não como “ligar o force_ssl e ir para produção”.
# idp-poc
