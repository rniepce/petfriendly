# 🐾 PetFriendly

Um jogo infantil de cuidar de bichinhos de estimação, feito em SwiftUI para iPhone (na horizontal). Pensado para crianças pequenas: tudo funciona com toques e arrastos simples, sem leitura obrigatória e sem compras ou anúncios.

Os pets têm **corpo inteiro desenhado em vetor** e são animados o tempo todo: andam pelo quarto, sentam, correm atrás da bola, mastigam a comida, piscam, abanam o rabo e se sacodem depois do banho. O jogo também tem **musiquinha de fundo** (estilo caixinha de música) e efeitos sonoros — tudo sintetizado pelo próprio app, sem arquivos de áudio. Dá para desligar a música no botão 🎵.

## Como jogar

1. **Petshop 🏪** — Na primeira vez, a criança visita o petshop e escolhe entre 6 bichinhos: cachorrinho 🐶, gatinho 🐱, coelhinho 🐰, hamster 🐹, papagaio 🦜 e unicórnio 🦄. Depois escolhe um nome (há sugestões prontas em botõezinhos, ou pode digitar).
2. **Em casa 🏡** — O pet mora na casinha, com quatro medidores no topo da tela:
   - 🍖 Fome
   - 🫧 Higiene
   - ⚽ Diversão
   - ⚡ Energia

   Os medidores descem devagar com o tempo, e o pet "fala" num balãozinho o que está precisando. O pet passeia sozinho pelo quarto, senta e descansa. Tocar nele faz um pulinho feliz; passar o dedo (fazer carinho) solta coraçõezinhos!
3. **Atividades (botões grandes embaixo):**
   - **Comer 🍎** — arraste a comida até a tigela; o pet corre até lá e come mastigando de verdade.
   - **Banho 🛁** — esfregue as sujeirinhas com o dedo: faz espuma! Depois vem o chuveirinho de enxágue e o pet se sacode todo.
   - **Brincar ⚽** — jogue a bola bem longe (com força!); o pet corre, busca e traz de volta.
   - **Dormir 🌙** — o pet deita na caminha e dorme respirando devagarinho até a energia encher.

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
├── Models/Pet.swift              # Espécies, cores, medidores e humor do pet
├── Game/GameViewModel.swift      # Estado do jogo, tempo passando, salvar/carregar
├── Audio/AudioManager.swift      # Música de fundo e efeitos, sintetizados em código
└── Views/
    ├── ContentView.swift         # Navegação entre telas
    ├── TitleView.swift           # Tela inicial com desfile de pets
    ├── PetShopView.swift         # Escolha e nome do pet (bichinhos animados)
    ├── HomeView.swift            # Casa, pet passeando, medidores e atividades
    ├── Activities/               # Comer, banho, brincar e dormir
    └── Components/
        ├── PetCharacterView.swift  # Pet de corpo inteiro, poses e animações
        └── ...                     # Botões, barras, balão de fala, partículas
```
