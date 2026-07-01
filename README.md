# Sistema Habitat

## Proposta do Aplicativo
O Sistema Habitat é uma solução de gestão jurídica focada em projetos sociais de regularização habitacional. Desenvolvido em Flutter, o aplicativo foi criado para centralizar, organizar e acelerar o andamento de processos complexos que envolvem a posse legal de terras e moradias para famílias de baixa renda. A ferramenta atua como um facilitador de fluxo de trabalho e comunicação de dados processuais entre estagiários, coordenadores e administradores.

## Função de Cada Tela
A arquitetura de navegação e as rotas mapeadas no ecossistema estruturam o fluxo lógico de uso por meio das seguintes interfaces:

1. **Login:** Interface inicial de autenticação que valida o e-mail e a senha do usuário através do AuthProvider, bloqueando acessos não autorizados e direcionando o usuário autenticado para a central do sistema.
2. **Menu Principal:** Painel central acessível após o login. Apresenta indicadores gerais, resumos de atividades e atalhos rápidos de navegação concentrados no componente global de scaffold (HabitatScaffold).
3. **Mural de Casos / Kanban:** Tela secundária estruturada visualmente em colunas que refletem o ciclo de vida da regularização (Triagem, Documentação, Em Processo Judicial e Finalizado). Permite gerenciar de maneira ágil a transição e a distribuição dos atendimentos habitacionais.
4. **Detalhes do Caso:** Sub-tela acessível a partir do clique direto em um card específico dentro do Mural de Casos. Exibe minuciosamente os dados do morador, CPF, descrição jurídica da demanda (como regularização de terreno ou emissão de escritura) e a equipe responsável.
5. **Novo Atendimento:** Formulário dedicado à inserção e coleta de dados cadastrais de novos cidadãos atendidos pelo projeto social.
6. **Relatórios:** Espaço para consolidação de dados quantitativos e geração de balanços sobre a eficiência dos processos concluídos e pendentes.
7. **Gestão de Usuários:** Interface restrita ao perfil master para o controle de acessos, vinculação de cargos e moderação dos membros cadastrados no sistema.

## Relação com as Disciplinas
Trabalhamos de forma unificada utilizando a mesma regra de negócio para atender e exercitar as necessidades práticas de duas vertentes essenciais da nossa formação:

### 1. Engenharia de Software
A aplicação dos fundamentos da disciplina cobriu todo o ciclo de concepção do software. Iniciamos com um levantamento de requisitos para compreender o fluxo jurídico-administrativo da regularização de terras e traduzi-lo em requisitos funcionais e não funcionais. Isso resultou no mapeamento de níveis de acesso e perfis de usuários (Master, Coordenador, Estagiário). No código, as boas práticas de engenharia refletem-se na modularidade da estrutura do ecossistema, no uso de uma gerência de estado limpa e reativa com Provider e no desacoplamento de rotas por meio do GoRouter, promovendo alta manutenibilidade e reuso de componentes.

### 2. Redes de Computadores / Cloud Computing
Para que o front-end em Flutter deixasse de ser apenas uma aplicação local, integramos o projeto ao ambiente de nuvem realizando o deploy na infraestrutura da AWS Academy. Essa etapa permitiu aplicar conceitos práticos de conectividade e redes de computadores, englobando o provisionamento de recursos em nuvem, configuração de grupos de segurança, liberação de portas de tráfego, roteamento de requisições e a estruturação de uma rede confiável para que a aplicação consiga se comunicar com as APIs externas de forma segura, garantindo alta disponibilidade e desempenho para os usuários finais.
