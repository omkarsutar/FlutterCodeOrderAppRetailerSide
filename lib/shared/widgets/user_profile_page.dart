import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/validators/form_validators.dart';
import 'shared_widget_barrel.dart';
import '../../features/postLogin/users/user_barrel.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _routeController;
  bool _hasImageError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _routeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(ModelUser profile) async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        ModelUserFields.fullName: _nameController.text,
        ModelUserFields.preferredRouteId: _routeController.text,
      };

      await Supabase.instance.client
          .from(ModelUserFields.table)
          .update(updatedData)
          .eq(ModelUserFields.userId, profile.userId);

      await ref.read(authServiceProvider).loadAndStoreUserProfile();
      SnackbarUtils.showSuccess('Profile updated!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(enrichedUserProfileProvider);
    final avatarUrl = ref.watch(userAvatarUrlProvider);
    final theme = Theme.of(context);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('No profile found')));
        }

        // Initialize controllers with profile data if empty
        if (_nameController.text.isEmpty && profile.fullName != null) {
          _nameController.text = profile.fullName!;
        }
        if (_routeController.text.isEmpty && profile.preferredRouteId != null) {
          _routeController.text = profile.preferredRouteId!;
        }

        final fullName = profile.fullName ?? '';
        final initials = fullName.isNotEmpty
            ? fullName.trim().split(' ').take(2).map((e) => e[0]).join()
            : '?';

        return Scaffold(
          appBar: CustomAppBar(title: 'Your Profile', showBack: false),
          drawer: const CustomDrawer(),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar
                    ClipOval(
                      child: Container(
                        width: 100,
                        height: 100,
                        color: theme.colorScheme.primaryContainer,
                        child: avatarUrl != null && !_hasImageError
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: Text(
                                    initials.toUpperCase(),
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted && !_hasImageError) {
                                      setState(() => _hasImageError = true);
                                    }
                                  });
                                  return Center(
                                    child: Text(
                                      initials.toUpperCase(),
                                      style: theme.textTheme.displaySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  initials.toUpperCase(),
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName.isNotEmpty ? fullName : 'No Name',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.resolvedLabels['role_id_label'] ??
                          profile.roleId ??
                          'Unknown Role',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Form Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Personal Information',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                                validator: FormValidators.required(
                                  message: 'Enter your name',
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => _updateProfile(profile),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Update Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
