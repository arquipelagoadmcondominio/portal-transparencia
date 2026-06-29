PROJETO ARQUIPÉLAGO - PORTAL TRANSPARÊNCIA

Arquivos principais:
- index.html: site principal. Botão Área do Cliente removido. O menu Entrar no Portal abre portal.html.
- portal.html: página do portal com cabeçalho da Arquipélago, menu Voltar para o site, login de Morador e Administração.
- portal.css: layout do portal.
- portal.js: regras do portal e integração opcional com Supabase.
- supabase-arquipelago-portal-completo.sql: SQL completo para executar no Supabase.

Cloudflare Pages:
Framework preset: None
Build command: deixe vazio
Build output directory: /

Supabase:
1. Crie um projeto novo no Supabase.
2. Abra SQL Editor.
3. Cole e execute o arquivo supabase-arquipelago-portal-completo.sql.
4. Vá em Project Settings > API.
5. Copie Project URL e anon public key.
6. Abra portal.js e substitua:
   SUPABASE_URL = 'COLE_AQUI_A_URL_DO_SEU_SUPABASE'
   SUPABASE_ANON_KEY = 'COLE_AQUI_A_CHAVE_ANON_PUBLIC_DO_SUPABASE'
7. Envie novamente ao GitHub para o Cloudflare atualizar o deploy.

Login inicial da administração:
E-mail: admin@arquipelago.com
Senha: admin123

Observação:
Enquanto você não colocar as chaves do Supabase no portal.js, o sistema funciona em modo local no navegador usando localStorage. Após configurar o Supabase, passa a gravar no banco.
