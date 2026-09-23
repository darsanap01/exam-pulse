import 'models.dart';

/// Curated, subject-specific sample content. This is NOT AI-generated.
class DemoQuestion {
  final String text, explanation;
  final List<String> options;
  final int correct;
  const DemoQuestion(this.text, this.options, this.correct, this.explanation);
}

const demoBanks = <String, List<DemoQuestion>>{
  't1': [
    DemoQuestion('Which structure contains most DNA in a eukaryotic cell?', ['Nucleus', 'Ribosome', 'Cell wall', 'Golgi apparatus'], 0, 'Most eukaryotic DNA is stored in the nucleus; mitochondria also contain a small amount.'),
    DemoQuestion('Which organelle is the main site of aerobic ATP production?', ['Lysosome', 'Mitochondrion', 'Nucleolus', 'Vacuole'], 1, 'Mitochondria use cellular respiration to produce much of the cell’s ATP.'),
    DemoQuestion('Which feature occurs in plant cells but not typical animal cells?', ['Cell membrane', 'Nucleus', 'Cellulose cell wall', 'Mitochondrion'], 2, 'Plant cells possess a rigid cellulose cell wall outside their membrane.'),
    DemoQuestion('What controls the movement of many substances into and out of a cell?', ['Plasma membrane', 'Chromosome', 'Ribosome', 'Nucleolus'], 0, 'The selectively permeable plasma membrane regulates transport.'),
    DemoQuestion('Ribosomes are directly involved in which process?', ['Photosynthesis', 'Protein synthesis', 'Lipid storage', 'DNA replication'], 1, 'Ribosomes translate messenger RNA to build proteins.'),
    DemoQuestion('Which cell structure modifies and packages many proteins?', ['Cytoskeleton', 'Golgi apparatus', 'Cell wall', 'Nuclear envelope'], 1, 'The Golgi apparatus modifies, sorts, and packages proteins for transport.'),
    DemoQuestion('Which process allows water to cross a selectively permeable membrane?', ['Endocytosis', 'Osmosis', 'Active transport', 'Exocytosis'], 1, 'Osmosis is the net movement of water across a selectively permeable membrane.'),
    DemoQuestion('What is the primary role of chloroplasts?', ['Digesting waste', 'Photosynthesis', 'Cell division', 'Protein transport'], 1, 'Chloroplasts capture light energy to produce carbohydrates by photosynthesis.'),
    DemoQuestion('Which molecule is the immediate energy currency of cells?', ['ATP', 'DNA', 'Cellulose', 'RNA'], 0, 'ATP transfers usable energy to many cellular processes.'),
    DemoQuestion('What is the function of lysosomes in many animal cells?', ['Breaking down material', 'Making glucose', 'Storing genes', 'Making ribosomes'], 0, 'Lysosomes contain enzymes that digest macromolecules and worn-out components.'),
  ],
  't2': [
    DemoQuestion('Newton’s first law describes an object remaining at rest or in uniform motion unless acted on by what?', ['A balanced force', 'A net external force', 'Gravity only', 'Friction only'], 1, 'Motion changes when there is a nonzero net external force.'),
    DemoQuestion('A 3 kg object accelerates at 2 m/s². What is the net force?', ['1.5 N', '5 N', '6 N', '9 N'], 2, 'From F = ma, 3 × 2 = 6 newtons.'),
    DemoQuestion('Action and reaction forces act on which objects?', ['The same object', 'Different interacting objects', 'Only stationary objects', 'Only moving objects'], 1, 'Newton’s third-law force pairs act on two different interacting bodies.'),
    DemoQuestion('What is the SI unit of force?', ['Watt', 'Newton', 'Joule', 'Pascal'], 1, 'Force is measured in newtons (N).'),
    DemoQuestion('If net force is zero, acceleration is…', ['Always positive', 'Always negative', 'Zero', 'Increasing'], 2, 'F = ma means zero net force gives zero acceleration for constant positive mass.'),
    DemoQuestion('If the same net force acts on twice the mass, acceleration becomes…', ['Twice as large', 'Half as large', 'Four times as large', 'Unchanged'], 1, 'At fixed force, a = F/m, so doubling mass halves acceleration.'),
    DemoQuestion('Which quantity measures resistance to changes in velocity?', ['Mass', 'Speed', 'Pressure', 'Work'], 0, 'Mass is a measure of inertia.'),
    DemoQuestion('A 10 N force to the right and 4 N to the left act on a body. Net force is…', ['14 N right', '6 N left', '6 N right', '0 N'], 2, 'Opposing forces subtract: 10 − 4 = 6 N right.'),
    DemoQuestion('Which equation expresses Newton’s second law for constant mass?', ['F = ma', 'P = IV', 'E = mc²', 'v = d/t'], 0, 'Net force equals mass multiplied by acceleration.'),
    DemoQuestion('When you push a wall, the wall pushes back with…', ['No force', 'An equal and opposite force', 'A force always greater', 'A force always smaller'], 1, 'The wall exerts an equal-magnitude, opposite-direction force on you.'),
  ],
  't3': [
    DemoQuestion('What is the main energy source for photosynthesis?', ['Heat from soil', 'Sunlight', 'ATP from animals', 'Wind'], 1, 'Photosynthesis captures energy from light.'),
    DemoQuestion('Which gas is taken up by plants during photosynthesis?', ['Oxygen', 'Nitrogen', 'Carbon dioxide', 'Hydrogen'], 2, 'Carbon dioxide supplies carbon used to build sugars.'),
    DemoQuestion('Which pigment absorbs light in plant chloroplasts?', ['Hemoglobin', 'Chlorophyll', 'Keratin', 'Melanin'], 1, 'Chlorophyll is a principal light-absorbing pigment.'),
    DemoQuestion('Which gas is released by oxygenic photosynthesis?', ['Oxygen', 'Carbon dioxide', 'Methane', 'Nitrogen'], 0, 'Water splitting during light-dependent reactions releases oxygen.'),
    DemoQuestion('Where do light-dependent reactions occur?', ['Cytoplasm', 'Thylakoid membranes', 'Nucleus', 'Mitochondrial matrix'], 1, 'Photosystems and electron transport chains are in thylakoid membranes.'),
    DemoQuestion('The Calvin cycle primarily uses CO₂ to make…', ['Organic carbon compounds', 'Molecular oxygen', 'Sunlight', 'Water'], 0, 'The Calvin cycle fixes CO₂ into carbon-containing molecules that can form sugars.'),
    DemoQuestion('What enters a leaf mainly through stomata for photosynthesis?', ['Carbon dioxide', 'Glucose', 'Chlorophyll', 'Starch'], 0, 'CO₂ diffuses through stomatal pores into leaf tissues.'),
    DemoQuestion('Which molecule is split to replace electrons in photosystem II?', ['Glucose', 'Water', 'Oxygen', 'ATP'], 1, 'Water is split, providing electrons and releasing oxygen.'),
    DemoQuestion('Which pair is produced in light-dependent reactions and used in the Calvin cycle?', ['ATP and NADPH', 'DNA and RNA', 'O₂ and starch', 'CO₂ and water'], 0, 'ATP supplies energy and NADPH supplies reducing power for carbon fixation.'),
    DemoQuestion('Why does closing stomata often limit photosynthesis?', ['Less CO₂ can enter', 'More sunlight enters', 'Chlorophyll vanishes', 'Roots stop existing'], 0, 'Closed stomata limit CO₂ uptake, reducing substrate availability for carbon fixation.'),
  ],
};

List<Question> demoQuestions(String topicId, {required bool mock, required int offset}) {
  final bank = demoBanks[topicId] ?? demoBanks['t1']!;
  final count = mock ? bank.length : 5;
  return List.generate(count, (i) {
    final sourceIndex = (i + offset) % bank.length;
    final data = bank[sourceIndex];
    return Question('$topicId-$sourceIndex', data.text, data.options);
  });
}
