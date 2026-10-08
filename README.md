# congresso-2027

Cálculos do post ["O Congresso de 2027: mesma Câmara, outro Senado"](https://www.linkedin.com/feed/update/urn:li:activity:7514016362114228224/) (texto em `post.md`).

- `data/camara_2027.csv`, `data/senado_2027.csv`: os 513 deputados e 81 senadores de 2027 na escala comum 2019–2026 (dimensão 1 de um W-NOMINATE em espaço comum, Câmara + Senado). `origem` diz se a posição foi medida nas votações ou prevista; `bloco` (esquerda, centro-esquerda, centro, direita, pelo partido) é o grupo cujo resíduo empírico se usa na simulação; `erro` é o RMSE da previsão fora da amostra no bloco (0 para medidos). Modelo de previsão: dim 1 ~ (correlação do voto do candidato com o voto de Flávio e com o de Lula, por seção) × bloco + mediana do partido na escala anterior; validado nos novatos de 2023 com validação cruzada por pessoa: RMSE 0,22, R² 0,78 (esquerda 0,15; centro-esquerda 0,16; centro 0,26; direita 0,18). Estas são as previsões, registradas em outubro de 2026 (v2, 8 de outubro; a v1, com uma inclinação única para o coattail e erro normal único de 0,25, está no histórico do repositório e foi a base do texto publicado no LinkedIn; as diferenças estão em `post.md`, atualizado).
- `data/residuos.csv`: resíduos da validação cruzada dos modelos, por casa e bloco. Na simulação, cada previsto recebe um resíduo sorteado do seu bloco em vez de um erro normal; isso evita preencher artificialmente os vales entre os picos partidários.
- `data/camara_2023_26.csv`: deputados eleitos em 2022 com posição; `data/senado_2023_26.csv`: senadores que votaram na 57ª com posição.
- `data/governos.csv`: posição das lideranças de governo (Lula 2023–26; Bolsonaro 2019–22) em cada escala.
- `data/wnominate_camara_senado_2019_2026.csv`: o ajuste agrupado completo (W-NOMINATE, 2 dimensões, Câmara + Senado, legislaturas 56ª e 57ª, 1.118 linhas × 3.681 votações): deputados, senadores e as orientações de liderança como pseudo-legisladores (`pseudo = TRUE`; Governo, Maioria, Minoria e Oposição separados em 1º de janeiro de 2023). Erros-padrão por bootstrap (50 réplicas). É a escala usada para o Senado. Só a dimensão 1 é comparável entre as casas.
- `data/wnominate_camara_2019_2026.csv`: o mesmo ajuste só com a Câmara (escala usada para a Câmara; r = 0,999 com a anterior para deputados; erros-padrão com 3 réplicas, indicativos).
- `R/figs.R`: histograma, distribuição relativa por decis, densidade relativa (kernel sobre os ranks relativos, Handcock & Morris) e a comparação modelo × rótulo partidário para os previstos, Câmara 57ª contra 58ª; escreve `figures/`, `results/distribuicao_relativa.csv` e `results/densidade_relativa.csv`.
- `R/reldist.R`: distribuição relativa com o pacote `reldist` (Handcock & Morris): densidade relativa (método GAM), entropia e índices de polarização relativa (MRP, LRP, URP), com intervalos por simulação dos previstos; escreve `results/reldist_indices.csv` e `results/reldist_curva.csv`.
- `R/reldist_casas.R`: Senado em relação à Câmara na escala conjunta (2023–26 e 2027) e cada casa em 2027 em relação a 2023–26: densidade relativa, índices de polarização; `data/camara_2023_26_escala_conjunta.csv` e as colunas `dim1_conjunta`/`erro_conjunta` em `camara_2027.csv` são as posições da Câmara nessa escala.
- `R/post.R`: medianas, pivôs de 3/5, custo de governar (soma das distâncias ao centro até o limiar; quem está além do governo do próprio lado conta zero), com o erro de previsão simulado. Escreve `results/` e `figures/`.

```r
source("R/post.R")
```

Escalas, modelo de previsão e validação: projeto `bancada28` (não publicado), que gera os arquivos em `data/`.

## Avaliação das previsões (a fazer a partir de 2027)

O comparador é o que um governo montando coalizão, ou a imprensa analisando o Congresso, tem em dezembro de 2026: a aritmética partidária das cadeiras mais o histórico dos veteranos. Nos arquivos, isso é a coluna `base_partido` para quem nunca votou no Congresso (mediana do partido na escala 2019–2026: na Câmara, deputados do partido; no Senado, senadores do partido com n ≥ 3, senão todos os parlamentares) e a própria posição 2019–2026 para quem já votou (`dim1` das linhas com `origem` medida). `base_coligacao` (mediana da coligação presidencial de 2026) e `base_casa` (mediana da casa) são comparadores mais pobres, guardados por completude.

Escala: quando houver votações suficientes de 2027, estimar o W-NOMINATE agrupando 2019–2026 e 2027+ com as mesmas pontes, de modo que as posições de 2027 fiquem na escala em que as previsões foram feitas. Não escalar 2027 sozinho e mapear: localização e escala do W-NOMINATE só se identificam pelas pontes.

Três testes, na ordem de importância:

1. **Novatos, posição.** Para as linhas com `origem` começando em "previsto": `dim1` (previsão) e `base_partido` contra a posição medida em 2027. RMSE, R² fora da amostra e Spearman, no total e dentro de cada partido com n ≥ 10. O teste principal é o de dentro do partido: a aritmética partidária não ordena ninguém dentro de um partido, então qualquer correlação positiva ali é ganho. Expectativa registrada, da validação com os novatos de 2023: RMSE 0,25 (previsão) contra 0,28 (partido); dentro do partido, correlação de 0,6 no PL, 0,5 no PP, zero no PT e no MDB.
2. **Veteranos, persistência.** Para as linhas com posição medida: a posição 2019–2026 contra a posição de 2027, com `base_partido` como comparador. É o teste da hipótese de posição fixa em que tudo o mais se apoia; a posição própria deve bater a mediana do partido com folga.
3. **Agregados do post.** Mediana, faixa entre os pivôs de 3/5 e custo de governar realizados em 2027, por casa, contra os valores projetados e seus intervalos em `results/`.

Teste secundário, no nível do voto: por votação de 2027, estimar nos demais legisladores o ponto de corte (probit do voto na posição) e a maioria de cada partido, e prever o voto de cada um pela sua posição de dezembro de 2026 ou pela maioria do seu partido. No análogo com a 57ª (posições de dezembro de 2022, 415 mil votos), a maioria do partido acertou 88,6 % e a posição 83,1 % (83,9 % em duas dimensões). Como preditor de votos um a um, o rótulo partidário é o que se espera que vença; a posição serve para pôr todos na mesma escala.

## Depois do segundo turno (25/10/2026)

Duas peças das previsões dependem de quem governa, porque foram estimadas sob o governo Lula (novatos de 2023):

1. **Resíduos do centrão.** Em 2023, parte dos novatos do centrão foi parar à esquerda da mediana do partido; são sobretudo os do Nordeste (resíduo médio −0,11, contra +0,19 no Sul), e a participação de Lula no estado prevê esse desvio (−0,56 por ponto de participação, p < 0,001). O desnível regional dentro do centrão não existia sob Bolsonaro (56ª: Nordeste −0,02, Sul +0,05 em relação à mediana do centrão; 57ª: −0,07 e +0,24): é alinhamento com o governo do dia, não traço do eleitorado. Com governo de esquerda, a sorteio dos resíduos vale como está e o modelo pode incorporar a participação de Lula no estado por bloco (RMSE nos novatos de 2023 de 0,226 para 0,216; `notes/predicao_57/regiao.R` no projeto de origem). Com governo de direita, o sinal desse componente provavelmente se inverte e o modelo deve ficar na v2 sem o termo regional, com os resíduos do centrão centrados.
2. **A corcova em r ≈ 0,3 da densidade relativa da Câmara** é esse mesmo componente; não entra nos números do post (medianas, pivôs, custos), que dependem pouco dele.

A composição regional também explica parte da diferença entre as casas: reponderando a Câmara de 2023–26 para a distribuição regional do Senado (Norte, Nordeste e Centro-Oeste têm 75 % das cadeiras do Senado e 51 % da Câmara), a proporção na banda central vai de 0,41 para 0,46, a do Senado; a mediana não (0,13 reponderada, 0,08 no Senado): a bancada nordestina do Senado está bem à esquerda dos deputados nordestinos (−0,21 contra 0,04).

## Dois cenários de governo (registrados antes do segundo turno)

`R/cenarios.R` recalcula medianas, pivôs e custos da Câmara com os 180 previstos tratados de três formas (`results/cenarios.csv`; colunas `dim1_esq` e `dim1_dir` em `camara_2027.csv`; resíduos por cenário em `residuos.csv`):

- **neutro**: o modelo v2 sem termo regional, resíduos da coorte de 2023 (é o que está no post);
- **esquerda**: a mesma especificação mais a participação do candidato do PT no estado × bloco, coeficientes e resíduos estimados na coorte de 2023 (novatos da 57ª sob o governo Lula; RMSE 0,216, R² 0,79); coeficiente da participação do PT no estado, centrão: −0,50;
- **direita**: a mesma especificação estimada na coorte de 2019 (novatos da 56ª sob Bolsonaro, preditores de 2018, alvo na escala 2015–22 levado à escala 2019–26 pela reta entre as duas; RMSE 0,183, R² 0,82); coeficiente regional do centrão: −0,07.

Câmara 2027, previstos sorteados com os resíduos do cenário:

| | neutro | esquerda | direita | 2023–26 |
|---|---|---|---|---|
| mediana | 0,11 | 0,12 | 0,13 | 0,12 |
| pivôs de 3/5 | 0,01–0,18 | 0,02–0,18 | 0,05–0,20 | 0,03–0,18 |
| custo, governo na posição de Lula, maioria | 88,5 | 88,9 | 92,0 | 90,5 |
| custo, governo na posição de Bolsonaro, maioria | 67,7 | 65,8 | 74,5 | 74,0 |

Leitura: com governo de esquerda, os novatos do centrão do Nordeste se deslocam para a esquerda e os do PL para a cauda direita, e a Câmara fica um pouco mais barata para os dois lados; com governo de direita, as votações não separam os novatos do PL do centrão governista (na 56ª, PL e centrão eram indistinguíveis na dimensão 1), os novatos do PL ficam previstos em 0,40 em vez de 0,73, e a Câmara de 2027 custa o mesmo que a de 2023–26 para os dois lados. O Senado não muda entre cenários (modelo sem separação por governo). Depois de 25/10, o cenário correspondente passa a ser a previsão; o outro fica como contrafactual registrado.
