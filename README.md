# congresso-2027

Cálculos do post "O Congresso de 2027: mesma Câmara, outro Senado" (`post.md`).

- `data/camara_2027.csv`, `data/senado_2027.csv`: os 513 deputados e 81 senadores de 2027 na escala comum 2019–2026 (dimensão 1 de um W-NOMINATE em espaço comum, Câmara + Senado). `origem` diz se a posição foi medida nas votações ou prevista (partido, coligação e correlação com o voto presidencial de 2026); `erro` é o RMSE da previsão fora da amostra (0 para medidos). Estas são as previsões, registradas em outubro de 2026.
- `data/camara_2023_26.csv`: deputados eleitos em 2022 com posição; `data/senado_2023_26.csv`: senadores que votaram na 57ª com posição.
- `data/governos.csv`: posição das lideranças de governo (Lula 2023–26; Bolsonaro 2019–22) em cada escala.
- `R/post.R`: medianas, pivôs de 3/5, custo de governar (soma das distâncias ao centro até o limiar; quem está além do governo do próprio lado conta zero), com o erro de previsão simulado. Escreve `results/` e `figures/`.

```r
source("R/post.R")
```

Escalas, modelo de previsão e validação: projeto `bancada28` (não publicado), que gera os arquivos em `data/`.
