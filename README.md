# 🐾 PetFriendly

Um jogo infantil de cuidar de bichinhos de estimação, feito em SwiftUI para iPhone (na horizontal). Pensado para crianças pequenas: tudo funciona com toques e arrastos simples, sem leitura obrigatória e sem compras ou anúncios.

## Como jogar

1. **Petshop 🏪** — Na primeira vez, a criança visita o petshop e escolhe entre 6 bichinhos: cachorrinho 🐶, gatinho 🐱, coelhinho 🐰, hamster 🐹, papagaio 🦜 e unicórnio 🦄. Depois escolhe um nome (há sugestões prontas em botõezinhos, ou pode digitar).
2. **Em casa 🏡** — O pet mora na casinha, com quatro medidores no topo da tela:
   - 🍖 Fome
   - 🫧 Higiene
   - ⚽ Diversão
   - ⚡ Energia

   Os medidores descem devagar com o tempo, e o pet "fala" num balãozinho o que está precisando. Tocar no pet dá carinho (soltam coraçõezinhos!).
3. **Atividades (botões grandes embaixo):**
   - **Comer 🍎** — arraste as frutinhas e a comida favorita até a boca do pet.
   - **Banho 🛁** — esfregue as sujeirinhas com o dedo (a esponja segue o toque) até o pet ficar limpinho.
   - **Brincar ⚽** — arraste e solte a bola no quintal; o pet corre para buscar.
   - **Dormir 🌙** — o pet dorme sob as estrelas até a energia encher; depois é só acordar!

   Cada medidor que fica cheio rende uma estrela ⭐ de recompensa.

O pet fica salvo no aparelho — ao abrir o jogo de novo, ele continua de onde parou. Também dá para voltar ao petshop e adotar outro bichinho.

## Como rodar

1. Abra `PetFriendly.xcodeproj` no **Xcode 16** (ou mais novo).
2. Em *Signing & Capabilities*, selecione seu time de desenvolvimento.
3. Escolha um iPhone (simulador ou aparelho) e aperte **Run** (⌘R).

- Requer **iOS 17** ou mais novo.
- O jogo roda **somente na horizontal** (landscape), com a barra de status escondida.

## Estrutura do código

```
PetFriendly/
├── PetFriendlyApp.swift          # Entrada do app
├── Models/Pet.swift              # Espécies, medidores e humor do pet
├── Game/GameViewModel.swift      # Estado do jogo, tempo passando, salvar/carregar
└── Views/
    ├── ContentView.swift         # Navegação entre telas
    ├── TitleView.swift           # Tela inicial
    ├── PetShopView.swift         # Escolha e nome do pet
    ├── HomeView.swift            # Casa, medidores e botões de atividade
    ├── Activities/               # Comer, banho, brincar e dormir
    └── Components/               # Botões, barras, balão de fala, partículas
```
