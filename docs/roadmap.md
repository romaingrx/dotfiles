# Nix Configuration Roadmap

## Current Structure

```
.
├── flake.nix              # Main flake configuration
├── modules/               # Shared modules
│   ├── darwin/           # macOS-specific modules
│   └── home/             # Home-manager modules
├── hosts/                # Host-specific configurations
│   └── goddard/         # Single host configuration
└── profiles/            # User profiles
```

### Current Architecture Analysis

1. **Strengths**:
   - Basic separation of concerns (modules, hosts, profiles)
   - Working Darwin/macOS configuration
   - Home-manager integration
   - Support for multiple users on the same system

2. **Limitations**:
   - Limited host extensibility
   - Mixed concerns in module structure
   - No clear separation between system types (Darwin vs NixOS)
   - Lack of role-based configurations
   - No shared configurations between different systems
   - Limited reusability of common configurations

## Proposed Improvements

### 1. Restructure Project Layout

```
.
├── flake.nix
├── lib/                  # Shared Nix functions and utilities
├── modules/
│   ├── core/            # Core modules shared across all systems
│   │   ├── common/      # System-agnostic configurations
│   │   ├── darwin/      # Darwin-specific core modules
│   │   └── nixos/       # NixOS-specific core modules
│   ├── roles/           # Role-based configurations
│   │   ├── workstation/
│   │   ├── server/
│   │   └── development/
│   └── profiles/        # Specific configuration profiles
│       ├── users/       # User-specific configurations
│       ├── desktop/     # Desktop environment configs
│       └── development/ # Development tool configs
├── hosts/
│   ├── darwin/          # Darwin hosts
│   │   └── goddard/
│   └── nixos/          # NixOS hosts (future)
└── overlays/           # Custom package overlays
```

## Action Items

### Phase 1: Project Restructuring
- [ ] Create new directory structure following the proposed layout
- [ ] Move existing configurations to appropriate locations
- [ ] Create a lib directory for shared Nix functions
- [ ] Implement basic overlays structure

### Phase 2: Core Module Reorganization
- [ ] Separate system-agnostic configurations into `modules/core/common`
- [ ] Move Darwin-specific configurations to `modules/core/darwin`
- [ ] Create placeholder for NixOS configurations in `modules/core/nixos`
- [ ] Implement shared module utilities in `lib`

### Phase 3: Role-Based Configuration
- [ ] Define common roles (workstation, development, etc.)
- [ ] Create role-specific configurations in `modules/roles`
- [ ] Implement role composition system
- [ ] Document role usage and composition

### Phase 4: Profile Enhancement
- [ ] Move user configurations to `modules/profiles/users`
- [ ] Create reusable desktop environment profiles
- [ ] Implement development tool profiles
- [ ] Document profile system and usage

### Phase 5: Host Configuration
- [ ] Restructure host configurations to use roles and profiles
- [ ] Create template for new host additions
- [ ] Implement host-specific override system
- [ ] Document host configuration process

### Phase 6: Testing and Documentation
- [ ] Implement basic configuration tests
- [ ] Create comprehensive documentation
- [ ] Add example configurations
- [ ] Document common operations and maintenance

## Benefits of New Structure

1. **Improved Modularity**:
   - Clear separation of concerns
   - Easy to add new systems and configurations
   - Better reusability of common configurations

2. **Role-Based Management**:
   - Simplified system purpose definition
   - Easy to compose different roles
   - Consistent configuration across similar systems

3. **Better Maintainability**:
   - Clearer organization
   - Easier to understand and modify
   - Better documentation structure

4. **Enhanced Extensibility**:
   - Ready for multiple system types
   - Easy to add new roles and profiles
   - Flexible override system

## Migration Strategy

1. Start with core modules reorganization
2. Gradually move configurations to new structure
3. Test each component after migration
4. Keep existing system functional during transition
5. Document changes and update as needed

## Next Steps

1. Begin with Phase 1 actions
2. Create new branches for each phase
3. Test configurations in isolation
4. Gradually migrate existing system
5. Document progress and learnings 