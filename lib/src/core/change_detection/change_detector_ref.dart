abstract class ChangeDetectorRef {
  /// Marks all [ChangeDetectionStrategy#OnPush] ancestors as to be checked.
  ///
  /// <!-- TODO: Add a link to a chapter on OnPush components -->
  ///
  /// ```dart
  /// @Component(
  ///     selector: 'cmp',
  ///     changeDetection: ChangeDetectionStrategy.OnPush,
  ///     template: 'Number of ticks: {{numberOfTicks}}')
  /// class Cmp {
  ///   int numberOfTicks = 0;
  ///   ChangeDetectorRef ref;
  ///
  ///   Cmp(this.ref) {
  ///     new Timer(new Duration(milliseconds: 1000), () {
  ///       numberOfTicks++;
  ///       this.ref.markForCheck();
  ///     });
  ///   }
  /// }
  ///
  /// @Component(
  ///     selector: 'app',
  ///     changeDetection: ChangeDetectionStrategy.OnPush,
  ///     template: '''
  ///         <cmp><cmp>
  ///       ''',
  ///     directives: const [Cmp])
  /// class App {}
  ///
  /// void main() {
  ///   bootstrap(App);
  /// }
  /// ```
  ///
  void markForCheck();

  /// Detaches the change detector from the change detector tree.
  ///
  /// The detached change detector will not be checked until it is reattached.
  ///
  /// This can also be used in combination with [ChangeDetectorRef#detectChanges]
  /// to implement local change detection checks.
  ///
  /// <!-- TODO: Add a link to a chapter on detach/reattach/local digest -->
  ///
  /// ### Example
  ///
  /// The following example defines a component with a large list of readonly
  /// data. Imagine the data changes constantly, many times per second. For
  /// performance reasons, we want to check and update the list every five
  /// seconds. We can do that by detaching the component's change detector and
  /// doing a local check every five seconds.
  ///
  /// ```dart
  /// class DataProvider {
  ///   // in a real application the returned data will be different every time
  ///   List get data => [1, 2, 3, 4, 5];
  /// }
  ///
  /// @Component(
  ///     selector: 'giant-list',
  ///     template: '''
  ///        <li *ngFor="let d of dataProvider.data">Data {{d}}</lig>
  ///      ''',
  ///     directives: const [NgFor])
  /// class GiantList {
  ///   ChangeDetectorRef _ref;
  ///   DataProvider _dataProvider;
  ///
  ///   GiantList(this._ref, this._dataProvider) {
  ///     _ref.detach();
  ///     new Timer(new Duration(milliseconds: 5000), () {
  ///       _ref.detectChanges();
  ///     });
  ///   }
  ///
  ///   DataProvider get dataProvider => this._dataProvider;
  /// }
  ///
  /// @Component(
  ///     selector: 'app',
  ///     providers: const [DataProvider],
  ///     template: '''
  ///        <giant-list><giant-list>
  ///      ''',
  ///     directives: const [GiantList])
  /// class App {}
  ///
  /// void main() {
  ///   bootstrap(App);
  /// }
  /// ```
  ///
  void detach();

  /// Checks the change detector and its children.
  ///
  /// This can also be used in combination with [ChangeDetectorRef#detach] to
  /// implement local change detection checks.
  ///
  /// <!-- TODO: Add a link to a chapter on detach/reattach/local digest -->
  /// <!-- TODO: Add an example or remove the following description -->
  ///
  /// ### Example
  ///
  /// The following example defines a component with a large list of readonly
  /// data. Imagine, the data changes constantly, many times per second. For
  /// performance reasons, we want to check and update the list every five
  /// seconds.
  ///
  /// We can do that by detaching the component's change detector and doing a
  /// local change detection check every five seconds.
  ///
  /// See [ChangeDetectorRef#detach] for more information.
  ///
  void detectChanges();

  /// Checks the change detector and its children, and throws if any changes
  /// are detected.
  ///
  /// This is used in development mode to verify that running change detection
  /// doesn't introduce other changes.
  ///
  void checkNoChanges();

  /// Reattach the change detector to the change detector tree.
  ///
  /// This also marks OnPush ancestors as to be checked. This reattached change
  /// detector will be checked during the next change detection run.
  ///
  /// <!-- TODO: Add a link to a chapter on detach/reattach/local digest -->
  ///
  /// The following example creates a component displaying `live` data. The
  /// component will detach its change detector from the main change detector
  /// tree when the component's live property is set to false.
  ///
  /// ```dart
  /// class DataProvider {
  ///   int data = 1;
  ///
  ///   constructor() {
  ///     new Timer(new Duration(milliseconds: 500), () {
  ///       data *= 2;
  ///     });
  ///   }
  /// }
  ///
  /// @Component(
  ///     selector: 'live-data',
  ///     inputs: const ['live'],
  ///     template: 'Data: {{dataProvider.data}}')
  /// class LiveData {
  ///   ChangeDetectorRef _ref;
  ///   DataProvider _dataProvider;
  ///
  ///   LiveData(this._ref, this._dataProvider);
  ///
  ///   DataProvider get dataProvider => _dataProvider;
  ///
  ///   set live(value) {
  ///     if (value)
  ///       _ref.reattach();
  ///     else
  ///       _ref.detach();
  ///   }
  /// }
  ///
  /// @Component(
  ///     selector: 'app',
  ///     providers: const [DataProvider],
  ///     template: '''
  ///         Live Update: <input type="checkbox" [(ngModel)]="live">
  ///         <live-data [live]="live"><live-data>
  ///       ''',
  ///     directives: const [LiveData, FORM_DIRECTIVES])
  /// class App {
  ///   bool live = true;
  /// }
  ///
  /// void main(){
  ///   bootstrap(App);
  /// }
  /// ```
  ///
  void reattach();
}
