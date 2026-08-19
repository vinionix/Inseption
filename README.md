# Inseption — Docker Infrastructure

Projeto de infraestrutura e conteinerização desenvolvido no contexto da 42, com foco em entender como serviços separados são construídos, configurados, conectados e mantidos com Docker Compose.

A implementação atual orquestra **WordPress + MariaDB** em uma rede Docker dedicada, com volumes persistentes, configuração por ambiente e uso de Docker secrets para credenciais.

## Objetivo

Construir a infraestrutura sem depender de uma aplicação monolítica pronta e, no processo, praticar:

- criação de imagens;
- isolamento de serviços;
- comunicação entre containers;
- persistência de dados;
- configuração por variáveis de ambiente;
- gerenciamento de segredos;
- automação de build e execução.

## Arquitetura atual

```text
                 Docker Compose
                       │
           ┌───────────┴───────────┐
           │                       │
      WordPress  ─────────────> MariaDB
           │                       │
  wordpress_data             mariadb_data
           │                       │
           └──── inception network ┘
```

O `srcs/docker-compose.yml` atualmente define:

### WordPress

- build local em `requirements/wordpress`;
- acesso às variáveis do `.env`;
- secrets de banco e WordPress;
- volume persistente em `/var/www/html`;
- conexão à rede `inception`.

### MariaDB

- build local em `requirements/mariadb`;
- secrets para usuário/root do banco;
- persistência em `/var/lib/mysql`;
- conexão à mesma rede interna.

## Estrutura

```text
Inseption/
├── Makefile
└── srcs/
    ├── .env.example
    ├── docker-compose.yml
    ├── requirements/
    └── secrets/
```

A pasta `secrets/` do repositório contém documentação, não os arquivos reais de senha que o Compose espera em runtime.

## Configuração

Use o arquivo de exemplo como base:

```bash
cp srcs/.env.example srcs/.env
```

Preencha apenas valores locais/de desenvolvimento e **não versione o `.env` real**.

Os arquivos de senha referenciados pelo Compose também devem ser criados localmente conforme a documentação em `srcs/secrets/` e permanecer fora do Git.

## Persistência

A implementação usa bind mounts através de volumes nomeados:

- `mariadb_data`
- `wordpress_data`

No estado atual, os caminhos apontam para:

```text
/home/vfidelis/data/mariadb
/home/vfidelis/data/wordpress
```

Isso funciona no ambiente para o qual o projeto foi configurado, mas é uma limitação de portabilidade. Uma evolução natural é parametrizar esses caminhos.

## Rede

Os serviços compartilham uma rede bridge dedicada:

```text
inception
```

Isso permite comunicação interna entre WordPress e MariaDB sem colocar todos os serviços diretamente na rede padrão do host.

## Como executar

O repositório possui um `Makefile` para automatizar o fluxo. Antes de subir o ambiente, garanta que:

1. Docker e Docker Compose estejam instalados;
2. `srcs/.env` exista;
3. os arquivos de secrets necessários existam localmente;
4. os diretórios de dados existam ou sejam criados pelo fluxo definido no projeto.

Depois, use os alvos disponíveis no `Makefile` para build/subida/limpeza conforme a configuração atual do projeto.

## Limitações atuais

A documentação descreve o código que existe hoje:

- o Compose atual possui WordPress e MariaDB;
- uma camada Nginx/TLS não aparece no arquivo Compose atual;
- os caminhos de volumes estão vinculados ao usuário `/home/vfidelis`;
- o projeto ainda pode evoluir até a arquitetura completa esperada pelo exercício da 42.

## Segurança

Este repositório foi revisado para evitar confundir **estrutura de secrets** com **segredos reais**. Boas práticas para continuar o projeto:

- nunca commitar `.env` real;
- nunca commitar arquivos de senha;
- se uma credencial real entrar no histórico do Git, rotacioná-la mesmo após remover o arquivo;
- não colocar senha em `Dockerfile` ou imagem;
- preferir secrets/variáveis apenas no momento de execução.

## O que este projeto demonstra

- Docker e Docker Compose;
- infraestrutura como código em pequena escala;
- rede entre serviços;
- persistência de dados;
- separação de configuração e código;
- secrets e preocupação com exposição de credenciais;
- troubleshooting de serviços conteinerizados.

## Documentação

- [Technical Overview](docs/TECHNICAL_OVERVIEW.md) — topologia, persistência, networking, segurança, limitações e checklist de validação.

## Autor

Desenvolvido por [Vinícius Fidelis](https://github.com/vinionix) durante a formação na 42 Rio.
