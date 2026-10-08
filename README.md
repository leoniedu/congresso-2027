# congresso-2027

Cálculos do post ["O Congresso de 2027: mesma Câmara, outro Senado"](https://www.linkedin.com/feed/update/urn:li:activity:7514016362114228224/) (texto em `post.md`).

- `data/camara_2027.csv`, `data/senado_2027.csv`: os 513 deputados e 81 senadores de 2027 na escala comum 2019–2026 (dimensão 1 de um W-NOMINATE em espaço comum, Câmara + Senado). `origem` diz se a posição foi medida nas votações ou prevista (partido, coligação e correlação com o voto presidencial de 2026); `erro` é o RMSE da previsão fora da amostra (0 para medidos). Estas são as previsões, registradas em outubro de 2026.
- `data/camara_2023_26.csv`: deputados eleitos em 2022 com posição; `data/senado_2023_26.csv`: senadores que votaram na 57ª com posição.
- `data/governos.csv`: posição das lideranças de governo (Lula 2023–26; Bolsonaro 2019–22) em cada escala.
- `data/wnominate_camara_senado_2019_2026.csv`: o ajuste agrupado completo (W-NOMINATE, 2 dimensões, Câmara + Senado, legislaturas 56ª e 57ª, 1.118 linhas × 3.681 votações): deputados, senadores e as orientações de liderança como pseudo-legisladores (`pseudo = TRUE`; Governo, Maioria, Minoria e Oposição separados em 1º de janeiro de 2023). Erros-padrão por bootstrap (50 réplicas). É a escala usada para o Senado. Só a dimensão 1 é comparável entre as casas.
- `data/wnominate_camara_2019_2026.csv`: o mesmo ajuste só com a Câmara (escala usada para a Câmara; r = 0,999 com a anterior para deputados; erros-padrão com 3 réplicas, indicativos).
- `R/post.R`: medianas, pivôs de 3/5, custo de governar (soma das distâncias ao centro até o limiar; quem está além do governo do próprio lado conta zero), com o erro de previsão simulado. Escreve `results/` e `figures/`.

```r
source("R/post.R")
```

Escalas, modelo de previsão e validação: projeto `bancada28` (não publicado), que gera os arquivos em `data/`.

## Avaliação das previsões (a fazer a partir de 2027)

As colunas `base_partido`, `base_coligacao` e `base_casa` em `data/camara_2027.csv` e `data/senado_2027.csv` são os comparadores, fixados junto com as previsões: mediana do partido na escala 2019–2026 (na Câmara, deputados do partido; no Senado, senadores do partido com n ≥ 3, senão todos os parlamentares), mediana da coligação presidencial de 2026 (Lula / Flávio / nenhuma) e mediana da casa.

Protocolo: quando houver votações suficientes de 2027, estimar o W-NOMINATE agrupando 2019–2026 e 2027+ (mesmas pontes), de modo que as novas posições fiquem na escala em que as previsões foram feitas; depois, só para as linhas com `origem` começando em "previsto", comparar `dim1` e cada `base_*` com a posição medida: RMSE, R² fora da amostra e correlação de Spearman, no total e dentro de cada partido com n ≥ 10. A previsão vale alguma coisa se bater `base_partido`; na validação com os novatos de 2023, a margem foi de RMSE 0,28 (partido) para 0,25 (modelo), e a diferença esteve concentrada no PL.

Referência de hoje, nos membros com posição medida: RMSE da mediana do partido 0,22 na Câmara e 0,22 no Senado; da coligação 0,24 e 0,29; da casa 0,50 e 0,51. O modelo afasta os previstos da mediana do partido em 0,10 (RMSE) na Câmara.
