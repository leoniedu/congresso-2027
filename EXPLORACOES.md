# Explorações (não fazem parte da previsão registrada)

Material exploratório mantido para referência. A previsão registrada é a do modelo v2 (uma versão, sem termos regionais nem cenários de governo), descrita no README.

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
