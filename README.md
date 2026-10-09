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

Explorações posteriores (termo regional, cenários por governo) estão em `EXPLORACOES.md`; não fazem parte da previsão registrada.
