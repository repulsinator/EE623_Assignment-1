# EE623 Assignment-1: Hindi Phonetic Analysis

## Overview
This repository contains voice samples of Hindi vowels and consonants collected and analyzed for EE623 Assignment-1. The project focuses on analyzing the phonetic characteristics of Hindi speech sounds based on their place and manner of articulation.

## Language
**Hindi** (Devanagari script)

## Recording Specifications
- **Sampling Frequency:** 44.1 kHz
- **Bit Resolution:** 16 bits/sample
- **Recording Tool:** Praat/Wavesurfer/Audacity

## Repository Structure

### Vowels Recorded

#### Primary Vowels
| Type | Short | Long |
|------|-------|------|
| Unrounded low central | अ (a) | आ (ā) |
| Unrounded high front | इ (i) | ई (ī) |
| Rounded high back | उ (u) | ऊ (ū) |

**Files:**
- `अ :a: - Unrounded low central.wav`
- `इ :i: - Unrounded high front.wav`
- `उ :u: - Rounded high back.wav`

#### Secondary Vowels
| Type | Sound |
|------|-------|
| Unrounded front | ए (e), ऐ (ai) |
| Rounded back | ओ (o), औ (au) |

### Consonants Recorded

#### Plosives (Sparshta)
Organized by place and manner of articulation:

**Voiced Consonants:**
- `ग :ga: - Unaspirated voiced.wav` (Velar - Unaspirated)
- `घ :gha: - Aspirated voiced.wav` (Velar - Aspirated)
- `ज :ja: - Unaspirated voiced.wav` (Palatal - Unaspirated)
- `झ :jha: - Aspirated voiced.wav` (Palatal - Aspirated)

## Analysis Performed

### Objective 1: Spectral Analysis
1. **Narrowband Spectrogram Analysis**
   - Computed for voiced examples
   - Pitch deduction from harmonic structure

2. **Pitch Estimation**
   - Using Average Magnitude Difference (AMD) function
   - Time-domain pitch tracking

3. **Wideband Spectrogram Analysis**
   - Formant frequency identification
   - First three formant (F1, F2, F3) contour marking

### Objective 2: Cepstral Analysis
1. Estimated average values of first three formant frequencies
2. Calculated average pitch values
3. Analysis over 6 consecutive frames
4. Generated framewise plots of:
   - Cepstrally smoothed spectra
   - Cepstral sequences

## Deliverables
- Voice sample recordings (.wav files)
- Analysis report (PDF)
- MATLAB/Python code with comments
- Spectrograms and plots

## Phonetic Categories Covered

### By Place of Articulation
- Velar (Kantya): क, ख, ग, घ, ङ
- Palatal (Tālavya): च, छ, ज, झ, ञ
- Retroflex (Mūrdhanya): ट, ठ, ड, ढ, ण
- Dental (Dantya): त, थ, द, ध, न
- Labial (Öshtya): प, फ, ब, भ, म

### By Manner of Articulation
- Unaspirated Voiceless (Alpaprāna Śvāsa)
- Aspirated Voiceless (Mahāprāna Śvāsa)
- Unaspirated Voiced (Alpaprāna Nāda)
- Aspirated Voiced (Mahāprāna Nāda)
- Nasal (Anunāsika Nāda)

## Usage
The voice samples can be used for:
- Phonetic research on Hindi speech sounds
- Speech processing algorithm development
- Acoustic analysis of Indian languages
- Educational purposes in speech technology courses

## Author
Tarun Kurethiya  
IIT Guwahati  
EE623 - Speech Signal Processing


*Note: All recordings are original and recorded specifically for this academic assignment.*
