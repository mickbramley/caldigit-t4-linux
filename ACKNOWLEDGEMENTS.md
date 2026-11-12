# Acknowledgements

This independent, noncommercial investigation was undertaken to keep a personally owned, fully functional CalDigit T4 Thunderbolt 3 RAID enclosure useful after the original software became outdated. It documents observed behavior on an Intel Mac host and an adapted Linux-native storage configuration on a 2012 Intel Mac mini running Debian 13. The repository also serves as a personal reinstallation reference and is shared freely in case it helps other owners.

## CalDigit

**CalDigit** designed and manufactured the T4 Thunderbolt 3 RAID enclosure. Its original engineering, hardware, firmware, RAID software and published technical documentation provided the subject and technical starting point of this investigation. The goal was to extend the useful life of this well-made device, not to replace or diminish CalDigit's original engineering. CalDigit did not participate in, review, sponsor or endorse this work. No rights in CalDigit technology or intellectual property are claimed.

## Investigation and research tools

- **Michael Bramley:** project conception, ownership and setup of the hardware, testing, experimental decisions, terminal operations, review of diagnostic evidence, practical verification and publication.
- **ChatGPT / OpenAI (GPT-6):** collaborative technical explanations, hypotheses, troubleshooting sequences, command suggestions, analysis and drafting assistance. AI-generated instructions were not autonomously executed or independently hardware-tested.
- **[Ghidra](https://ghidra-sre.org/):** reverse-engineering framework used to inspect relevant macOS software components.
- **Reverse Engineering Assistant (REA):** AI-assisted reverse-engineering analysis used during the investigation. Acknowledgement does not imply that its developers reviewed or endorsed the conclusions.

## Open-source infrastructure

Thanks to the maintainers and contributors of the **[Linux kernel](https://kernel.org/)** (Thunderbolt, PCIe, AHCI and storage subsystems), **[Debian](https://www.debian.org/)**, **mdadm**, **driverctl**, **smartmontools**, **Samba**, **Linux NFS utilities**, **Cockpit**, and the GNU and other command-line tools involved in the experiments.

**Apple** is acknowledged for the original Intel Mac host and macOS environment and for the Thunderbolt adapter used to connect the enclosure. Neither Apple nor any upstream software project is a project collaborator or endorser.

All third-party trademarks, software and other intellectual property remain subject to their respective owners and applicable licenses. See [LICENSE-NOTICE.md](LICENSE-NOTICE.md) and [References](docs/REFERENCES.md).
