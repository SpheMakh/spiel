cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement


inputs:
 random_seed: int
 telescope: string
 dtime: float
 freq0: float
 nchan: int
 config: File
 ra_min: float
 ra_max: float 
 dec_min: float
 dec_max: float
 scale: string
 size_x: int
 size_y: int
 fov: float
 pb_fwhm: float
 nsrc: int
 column: string
 weight: string
 randomise_pos: boolean
 sefd: float
 nant: int
 synthesis_min: float
 synthesis_max: float
 dfreq_min: float
 dfreq_max: float
 gain_errors: int
 gainamp_min_error: float 
 gainamp_max_error: float 
 gainphase_min_error: float 
 gainphase_max_error: float 
 flux_scale_min: float
 flux_scale_max: float
 antennas: Directory

outputs:
  dirty:
    type: File
    outputSource: rename_dirty/renamed
  skymodel:
    type: File
    outputSource: rename_skymodel/renamed
  psf:
    type: File
    outputSource: rename_psf/renamed
  settings:
    type: File
    outputSource: rename_settings/renamed
  mask:
    type: File
    outputSource: rename_mask/renamed


steps:
  randomize:
    run: ../steps/randomize.cwl
    in:
       random_seed: random_seed
       ra_min: ra_min
       a_max: ra_max
       dec_min: dec_min
       dec_max: dec_max
       dfreq_max: dfreq_max
       dfreq_min: dfreq_min
       synthesis_max: synthesis_max
       synthesis_min: synthesis_min
       flux_scale_min: flux_scale_min
       flux_scale_max: flux_scale_max
    out:
       [dec, ra, synthesis, dfreq, flux_scale]

  simms:
    run: ../steps/simms.cwl
    in:
      telescope: telescope
      ra: randomize/ra
      dec: randomize/dec
      synthesis: randomize/synthesis
      dtime: dtime
      freq0: freq0
      dfreq: randomize/dfreq
      nchan: nchan
      pos: antennas
      type:
        valueFrom: casa
    out:
      [ms]

  make_skymodel:
    run: ../steps/skymodel.cwl
    in:
      ra: randomize/ra
      dec: randomize/dec
      seed: random_seed
      freq0: freq0
      fov: fov
      pb_fwhm: pb_fwhm
      nsrc: nsrc
      sefd: sefd
      dtime: dtime
      dfreq: randomize/dfreq
      nant: nant
      flux_scale: randomize/flux_scale
    out:
      [skymodel]

  write_settings:
    run: ../steps/write_settings.cwl
    in:
      ra: randomize/ra
      dec: randomize/dec
      seed: random_seed
      freq0: freq0
      fov: fov
      pb_fwhm: pb_fwhm
      telescope: telescope
      dfreq: randomize/dfreq
      synthesis: randomize/synthesis
      nant: nant
      randomise_pos: randomise_pos
    out:
      [settings]

  simulator:
    run: ../steps/simulator.cwl
    in:
      ms: simms/ms
      config: config
      output_column: column
      skymodel: make_skymodel/skymodel
      sefd: sefd
      dtime: dtime
      dfreq: randomize/dfreq
      gain_errors: gain_errors
      gainamp_min_error: gainamp_min_error
      gainamp_max_error: gainamp_max_error
      gainphase_min_error: gainphase_min_error
      gainphase_max_error: gainphase_max_error
    out:
      [ms_out]

  wsclean:
    run: ../steps/wsclean.cwl
    in:
      size_x: size_x
      size_y: size_y
      scale: scale
      column: column
      weight: weight
      ms: simulator/ms_out
      make-psf:
        valueFrom: $(true)
    out:
      [cleaned,psf]

  model_mask:
    run: ../steps/model_mask.cwl
    in:
      skymodel: make_skymodel/skymodel
      fits_template: wsclean/cleaned
    out:
      [mask]

  rename_mask:
    run: ../steps/rename.cwl
    in:
      file: model_mask/mask
      prefix: random_seed
    out:
      - renamed

  rename_skymodel:
    run: ../steps/rename.cwl
    in:
      file: make_skymodel/skymodel
      prefix: random_seed
    out:
      - renamed

  rename_dirty:
    run: ../steps/rename.cwl
    in:
      file: wsclean/cleaned
      prefix: random_seed
    out:
      - renamed

  rename_psf:
    run: ../steps/rename.cwl
    in:
      file: wsclean/psf
      prefix: random_seed
    out:
      - renamed

  rename_settings:
    run: ../steps/rename.cwl
    in:
      file: write_settings/settings
      prefix: random_seed
    out:
      - renamed
