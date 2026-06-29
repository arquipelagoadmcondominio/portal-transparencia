PROJETO ATUALIZADO - ARQUIPÉLAGO ADMINISTRAÇÃO DE CONDOMÍNIOS

Arquivos principais alterados:
- index.html: textos, identidade, links e marca Arquipélago.
- style.css: paleta baseada na logo: azul oceano, azul onda, laranja pôr do sol, amarelo e verde suave.
- logo-arquipelago.jpeg: logo enviada aplicada na página principal, área do cliente e rodapé.
- supabase-arquipelago-portal.sql: estrutura inicial para criar o banco do Portal Transparência no Supabase.

Ajustes manuais necessários antes de publicar:
1. Trocar telefone, WhatsApp, e-mail e domínio pelos dados oficiais da Arquipélago.
2. Quando o subdomínio do portal estiver pronto, substituir:
   https://portal.arquipelagocondominios.com.br
3. No Supabase novo, abrir SQL Editor, colar todo o arquivo supabase-arquipelago-portal.sql e executar.
4. Configurar no projeto as variáveis do Supabase novo, se o portal usar SUPABASE_URL e SUPABASE_ANON_KEY/SERVICE_ROLE_KEY.

Observação:
Este ZIP enviado continha apenas o site institucional estático. Não havia, dentro dele, as páginas internas reais de login/painel do Portal Transparência. Por isso, eu deixei a identidade visual preparada no site e gerei o SQL completo para o banco do portal novo.
