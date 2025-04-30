# AWS Control Panel zur Administrierung von Ressourcen

![Titelbild](img/FutureControlPanel.jpg)

# Inhaltsverzeichnis

[toc]

## 1 Projektorganisation

```mermaid

flowchart LR
  subgraph Projekthierarchie
    direction TB
    subgraph Studierender

        Stud[Marlon Burri]
    end
    subgraph Dozenten
        direction LR
        Fachdozent[Fachdozent] --- Projektleiter[Projektleiter]
        Projektleiter --- Lehrgangsleiter[Lehrgangsleiter]
    end
  end
  Studierender --- Dozenten

```

## 2 Projektübersicht

### 2.1 Behandelte Module

- AWS-Base
- Infrastructure as Code

## 2.2 Problemstellung